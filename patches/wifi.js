'use strict';
'require form';
'require view';
'require uci';

/*
 * luci-app-guest-wifi view - v2 独立配置版 (2026-11-23)
 *
 * 设计变更（彻底修复 v1 的「添加按钮无反应」）：
 *   v1 及上游原版把访客网络存进 wireless 配置，靠 s.filter 只显示
 *   guest_wifi==='1' 的段。新建段与被 filter 隐藏之间形成冲突，且页面
 *   缺少可靠的 apply 入口，导致点击添加后看不到任何变化。
 *
 *   v2 改用独立 UCI 配置 guest-wifi 存储访客网络定义：
 *     - 该配置文件中每个段都是访客网络，无需 filter，addremove 正常显示；
 *     - 无线栈所需的 wifi-iface 段由 /etc/init.d/guest-wifi 在配置变更时
 *       自动同步生成（procd reload trigger 监听 guest-wifi）；
 *     - 页面只负责编辑 guest-wifi，职责单一，不再与 wireless 的 filter 耦合。
 *
 * 访客段字段：enabled / ssid / device / encryption / key / isolate / network
 */
return view.extend({
	load: function() {
		return Promise.all([
			uci.load('guest-wifi'),
			uci.load('wireless')
		]);
	},

	render: function() {
		var m = new form.Map('guest-wifi', _('Guest WiFi'),
			_('Guest WiFi provides a separate wireless network for guest access with isolated permissions.'));

		var s = m.section(form.TypedSection, 'guest-wifi', _('Guest WiFi Settings'));
		s.anonymous = true;
		s.addremove = true;
		/* 关键点：不使用 filter，也不覆盖 cfgvalue（原版覆盖会干扰控件渲染） */

		var o = null;

		o = s.option(form.Flag, 'enabled', _('Enable'), _('Enable this guest network'));
		o.rmempty = false;
		o.default = '1';

		o = s.option(form.Value, 'ssid', _('Network Name (SSID)'));
		o.rmempty = false;
		o.default = 'Guest';

		/* 从 wireless 的 wifi-device 动态生成 radio 列表 */
		o = s.option(form.ListValue, 'device', _('Radio'));
		var radios = uci.sections('wireless', 'wifi-device') || [];
		for (var i = 0; i < radios.length; i++) {
			var r = radios[i];
			var band = r.band ? (' ' + r.band) : '';
			o.value(r['.name'], r['.name'] + band);
		}
		if (!radios.length)
			o.value('radio0', 'radio0');
		o.default = radios.length ? radios[0]['.name'] : 'radio0';

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

		o = s.option(form.Value, 'network', _('Attach to Network'));
		o.default = 'lan';
		o.rmempty = false;
		o.description = _('Use lan for a basic guest SSID, or a dedicated guest interface for isolation.');

		return m.render();
	}
});
