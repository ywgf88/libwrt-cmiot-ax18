'use strict';
'require form';
'require view';
'require uci';

/*
 * luci-app-guest-wifi view 修复版 (2026-11-23)
 *
 * 上游原始实现存在两处缺陷，导致「添加」按钮点击后无任何反应：
 *   1. s.addremove=true 渲染出 Add 按钮，但默认 handleAdd 仅创建空的
 *      wifi-iface 段；s.filter 只放行 guest_wifi === '1' 的段，新建段
 *      没有该字段，立即被过滤隐藏 —— 表现为点了没反应。
 *   2. handleApply 调用了未 require 的 XHR.poll(2)，参数与用法均错误，
 *      保存时会抛 JS 异常。
 *
 * 本修复：
 *   - 覆盖 handleAdd：创建段时写入 guest_wifi='1' 等必填字段，使其通过
 *     filter 正常显示，并自动绑定一个可用 radio、设为 AP 模式。
 *   - 用标准的 uci.save -> uci.apply 流程替换错误的 XHR.poll 调用。
 */
return view.extend({
	load: function() {
		return uci.load('wireless');
	},

	render: function() {
		var m = new form.Map('wireless', _('Guest WiFi'),
			_('Guest WiFi provides a separate wireless network for guest access with isolated permissions.'));

		var s = m.section(form.TypedSection, 'wifi-iface', _('Guest WiFi Settings'));
		s.anonymous = true;
		s.addremove = true;
		s.filter = function(section_id) {
			return uci.get('wireless', section_id, 'guest_wifi') === '1';
		};
		s.cfgvalue = function(section_id) {
			return uci.get('wireless', section_id, 'guest_wifi');
		};

		/* 关键修复：新建段时写入标记与最小可用配置，避免被 filter 隐藏 */
		s.handleAdd = function(ev, name) {
			var config_name = this.uciconfig ?? this.map.config;
			var section_id = this.map.data.add(config_name, this.sectiontype, name);

			/* 打上访客标记，使 filter 放行该段 */
			this.map.data.set(config_name, section_id, 'guest_wifi', '1');
			/* 基础 AP 配置，保证新段创建后即可被无线栈识别 */
			this.map.data.set(config_name, section_id, 'mode', 'ap');
			this.map.data.set(config_name, section_id, 'network', 'lan');

			/* 自动绑定第一个可用的 radio（IPQ60xx 上通常为 2.4G radio0） */
			var radios = this.map.data.sections('wireless', 'wifi-device');
			if (radios.length)
				this.map.data.set(config_name, section_id, 'device', radios[0]['.name']);

			return this.map.save(null, true);
		};

		/* 次修复：移除未定义且用法错误的 XHR.poll，改用标准 apply 流程 */
		s.handleApply = function(section, ev) {
			uci.save(function() {
				uci.apply();
			});
		};

		var o = null;

		o = s.option(form.Flag, 'guest_wifi', _('Enable'),
			_('Enable guest WiFi network'));
		o.rmempty = false;
		o.default = '1';

		o = s.option(form.Value, 'ssid', _('Network Name (SSID)'));
		o.rmempty = false;
		o.default = 'Guest';

		o = s.option(form.ListValue, 'encryption', _('Encryption'));
		o.value('none', _('No Encryption'));
		o.value('psk2', _('WPA2-PSK'));
		o.value('sae', _('WPA3-SAE'));
		o.value('sae-mixed', _('WPA2/WPA3-Mixed'));
		o.rmempty = false;
		o.default = 'psk2';

		o = s.option(form.Value, 'key', _('Password'));
		o.depends('encryption', 'psk2');
		o.depends('encryption', 'sae');
		o.depends('encryption', 'sae-mixed');
		o.datatype = 'wpakey';
		o.rmempty = false;
		o.password = true;

		o = s.option(form.Flag, 'isolate', _('AP Isolation'),
			_('Prevents wireless clients from communicating with each other'));
		o.rmempty = false;
		o.default = '1';

		return m.render();
	}
});
