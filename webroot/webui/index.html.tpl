<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no">
<title>SideKey+</title>
<style>
:root{
  --bg:#08101d;
  --panel:#101a2c;
  --panel2:#16233a;
  --line:rgba(255,255,255,.10);
  --text:#eef4ff;
  --sub:#9db0d1;
  --blue:#4f8cff;
  --violet:#8b5cf6;
  --green:#22c55e;
  --red:#ef4444;
  --orange:#f59e0b;
  --shadow:0 18px 50px rgba(0,0,0,.28);
  --radius:22px;
}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html,body{
  margin:0;padding:0;
  background:linear-gradient(180deg,#07111d,#0a1322 35%,#0b1527);
  color:var(--text);
  font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Noto Sans SC","Microsoft YaHei",sans-serif
}
body{
  padding:16px 14px 110px;
  max-width:980px;
  margin:0 auto;
}
.header{padding:10px 4px 18px}
.title{font-size:28px;font-weight:800;letter-spacing:.3px}
.desc{margin-top:8px;color:var(--sub);font-size:14px;line-height:1.6}

.tabs{
  display:flex;
  gap:10px;
  margin:10px 0 18px;
  position:sticky;
  top:0;
  z-index:20;
  padding:10px 0 2px;
  backdrop-filter:blur(14px);
}
.tab{
  flex:1;
  border:none;
  border-radius:16px;
  background:rgba(255,255,255,.08);
  color:#dbeafe;
  padding:13px 12px;
  font-size:15px;
  font-weight:700;
  transition:.2s ease;
}
.tab.active{
  background:linear-gradient(135deg,var(--blue),var(--violet));
  color:#fff;
  box-shadow:0 10px 28px rgba(79,140,255,.28);
}
.tab:active{transform:scale(.98)}

.page{display:none}
.page.active{display:block}

.card{
  background:linear-gradient(180deg,rgba(17,26,44,.98),rgba(13,22,38,.98));
  border:1px solid var(--line);
  border-radius:var(--radius);
  box-shadow:var(--shadow);
  padding:16px;
  margin-bottom:14px;
}
.card h3{margin:0 0 14px;font-size:17px}
.card .sub{color:var(--sub);font-size:13px;line-height:1.6;margin-top:-4px;margin-bottom:12px}

.grid{
  display:grid;
  grid-template-columns:repeat(2,minmax(0,1fr));
  gap:12px;
}

@media (max-width:720px){
  .grid{
    grid-template-columns:1fr;
  }
}

.stat{
  background:linear-gradient(180deg,#16233a,#111a2d);
  border:1px solid rgba(255,255,255,.08);
  border-radius:18px;
  padding:14px;
}
.stat .label{color:var(--sub);font-size:13px}
.stat .value{margin-top:8px;font-size:22px;font-weight:800}

.badge{
  display:inline-flex;
  align-items:center;
  gap:7px;
  padding:7px 12px;
  border-radius:999px;
  font-size:13px;
  font-weight:700;
}
.badge::before{
  content:"";
  width:9px;
  height:9px;
  border-radius:50%;
  background:currentColor;
  box-shadow:0 0 0 4px rgba(255,255,255,.06);
}
.ok{color:#86efac;background:rgba(34,197,94,.12)}
.off{color:#fecaca;background:rgba(239,68,68,.12)}
.mid{color:#fde68a;background:rgba(245,158,11,.14)}

.field{margin-bottom:14px}
.label{display:block;font-size:14px;font-weight:700;margin-bottom:8px}
.help{color:var(--sub);font-size:12px;line-height:1.6;margin-top:6px}
.input,.select,.textarea{
  width:100%;
  border:none;
  outline:none;
  border-radius:16px;
  background:#0c1524;
  color:var(--text);
  border:1px solid rgba(255,255,255,.08);
  padding:14px 14px;
  font-size:14px;
}
.textarea{min-height:150px;resize:vertical}

.switch{
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap:12px;
  padding:14px;
  border-radius:18px;
  background:linear-gradient(180deg,#132037,#0e182b);
  border:1px solid rgba(255,255,255,.08);
  margin-bottom:12px;
}
.switch .left{flex:1}
.switch .left .name{font-size:15px;font-weight:800}
.switch .left .desc{margin-top:5px;font-size:12px;color:var(--sub)}

.toggle{position:relative;width:58px;height:34px;flex:0 0 auto}
.toggle input{display:none}
.slider{
  position:absolute;inset:0;
  background:#334155;
  border-radius:999px;
  transition:.2s ease;
}
.slider:before{
  content:"";
  position:absolute;
  width:26px;height:26px;
  left:4px;top:4px;
  border-radius:50%;
  background:#fff;
  transition:.2s ease;
  box-shadow:0 4px 14px rgba(0,0,0,.22);
}
.toggle input:checked + .slider{
  background:linear-gradient(135deg,var(--blue),var(--violet));
}
.toggle input:checked + .slider:before{
  transform:translateX(24px);
}

.segment{
  display:grid;
  grid-template-columns:repeat(4,minmax(0,1fr));
  gap:8px;
}
.segment button{
  border:none;
  padding:12px 10px;
  min-height:50px;
  border-radius:14px;
  background:linear-gradient(180deg,#132037,#0e182b);
  color:#dbeafe;
  font-weight:700;
  font-size:13px;
  line-height:1.35;
  text-align:center;
  word-break:break-word;
  white-space:normal;
  border:1px solid rgba(255,255,255,.08);
  transition:.18s ease;
}
.segment button.active{
  background:linear-gradient(135deg,var(--blue),var(--violet));
  color:#fff;
  border-color:transparent;
  box-shadow:0 8px 24px rgba(79,140,255,.22);
}
.segment button:active{transform:scale(.98)}

@media (max-width:720px){
  .segment{grid-template-columns:repeat(4,minmax(0,1fr))}
  .segment button{
    font-size:12px;
    padding:10px 8px;
    min-height:48px;
  }
}

.hidden{display:none!important}

.suggest{
  margin-top:8px;
  display:grid;
  gap:8px;
  max-height:260px;
  overflow:auto;
}
.app-item{
  display:flex;
  align-items:center;
  gap:10px;
  padding:10px 12px;
  border-radius:14px;
  background:#0f192c;
  border:1px solid rgba(255,255,255,.06);
}
.app-item .meta{min-width:0;flex:1}
.app-item .meta .name{
  font-size:14px;
  font-weight:800;
  white-space:nowrap;
  overflow:hidden;
  text-overflow:ellipsis;
}
.app-item .meta .pkg{
  font-size:12px;
  color:var(--sub);
  white-space:nowrap;
  overflow:hidden;
  text-overflow:ellipsis;
}

.action-overview{
  display:grid;
  gap:10px;
}
.action-row{
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap:12px;
  padding:12px 14px;
  border-radius:16px;
  background:linear-gradient(180deg,#132037,#0e182b);
  border:1px solid rgba(255,255,255,.08);
}
.action-row .key{
  flex:0 0 auto;
  color:#dbeafe;
  font-size:14px;
  font-weight:800;
}
.action-row .act{
  min-width:0;
  text-align:right;
  color:#fff;
  font-size:14px;
  font-weight:700;
  overflow:hidden;
  text-overflow:ellipsis;
  white-space:nowrap;
}

.defaults-card.hidden{
  display:none!important;
}

.kv{
  display:grid;
  grid-template-columns:110px 1fr;
  gap:8px 12px;
  font-size:13px;
}
.kv div:nth-child(odd){color:var(--sub)}

.link-list{
  display:grid;
  gap:10px;
  margin-top:12px;
}
.link-btn{
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap:12px;
  padding:14px 16px;
  border-radius:16px;
  text-decoration:none;
  color:#fff;
  background:linear-gradient(135deg,#1d3354,#29446e);
  border:1px solid rgba(255,255,255,.08);
  font-size:14px;
  font-weight:700;
  min-width:0;
}
.link-btn .txt{
  min-width:0;
  overflow:hidden;
  text-overflow:ellipsis;
  white-space:nowrap;
}
.link-btn .tag{
  flex:0 0 auto;
  font-size:12px;
  color:#bfdbfe;
}
.link-btn:active{transform:scale(.99)}

.toast{
  position:fixed;
  left:50%;
  bottom:22px;
  transform:translateX(-50%) translateY(20px);
  min-width:220px;
  max-width:90vw;
  padding:12px 16px;
  border-radius:16px;
  background:rgba(8,13,24,.92);
  color:#fff;
  border:1px solid rgba(255,255,255,.08);
  box-shadow:0 18px 50px rgba(0,0,0,.35);
  font-size:14px;
  font-weight:700;
  opacity:0;
  pointer-events:none;
  transition:.22s ease;
  z-index:99;
}
.toast.show{
  opacity:1;
  transform:translateX(-50%) translateY(0);
}

.fab-wrap{
  position:fixed;
  right:16px;
  bottom:18px;
  z-index:80;
  display:flex;
  flex-direction:column;
  gap:10px;
  align-items:flex-end;
}
.fab{
  appearance:none;
  border:none;
  min-width:132px;
  max-width:84vw;
  min-height:50px;
  padding:0 16px;
  border-radius:18px;
  color:#fff;
  font-size:14px;
  font-weight:800;
  box-shadow:0 14px 30px rgba(0,0,0,.28);
  border:1px solid rgba(255,255,255,.08);
  backdrop-filter:blur(10px);
}
.fab.primary{background:linear-gradient(135deg,var(--blue),var(--violet))}
.fab.green{background:linear-gradient(135deg,#16a34a,#22c55e)}
.fab.red{background:linear-gradient(135deg,#dc2626,#ef4444)}
.fab.gray{background:linear-gradient(135deg,#334155,#475569)}
.fab.orange{background:linear-gradient(135deg,#d97706,#f59e0b)}
.fab:active{transform:scale(.98)}
.fab[disabled]{opacity:.55;filter:grayscale(.16)}
.fab.loading{pointer-events:none}
.fab.loading::after{
  content:"";
  width:16px;height:16px;
  border:2px solid rgba(255,255,255,.35);
  border-top-color:#fff;
  border-radius:50%;
  display:inline-block;
  vertical-align:-3px;
  margin-left:8px;
  animation:spin .8s linear infinite;
}

code{
  background:rgba(255,255,255,.06);
  padding:2px 6px;
  border-radius:8px;
}
@keyframes spin{
  to{transform:rotate(360deg)}
}
</style>
</head>
<body>
  <div class="header">
    <div class="title">SideKey+</div>
    <div class="desc">一加三段式侧边键与音量键增强模块，支持快捷动作、自定义 Shell 与 Java CameraManager 手电筒。</div>
  </div>

  <div class="tabs">
    <button class="tab active" data-tab="home">主页</button>
    <button class="tab" data-tab="config">配置</button>
    <button class="tab" data-tab="actions">动作</button>
    <button class="tab" data-tab="about">关于</button>
  </div>

  <div id="page-home" class="page active">
    <div class="card">
      <h3>运行状态</h3>
      <div class="grid">
        <div class="stat">
          <div class="label">三段键后端</div>
          <div class="value"><span id="backendBadge" class="badge off">未运行</span></div>
        </div>
        <div class="stat">
          <div class="label">音量键服务</div>
          <div class="value"><span id="keydBadge" class="badge off">未运行</span></div>
        </div>
        <div class="stat">
          <div class="label">三段键当前值</div>
          <div class="value" id="sliderValueText">--</div>
        </div>
        <div class="stat">
          <div class="label">音量键模式</div>
          <div class="value" id="keyModeText">--</div>
        </div>
      </div>
    </div>

    <div class="card">
      <h3>键位动作</h3>
      <div id="homeActionOverview" class="action-overview"></div>
    </div>
  </div>

  <div id="page-config" class="page">
    <div class="card">
      <h3>基础配置</h3>

      <div class="field">
        <label class="label">Web 端口</label>
        <input id="WEB_PORT" class="input" type="number" inputmode="numeric" placeholder="__WEB_PORT__">
      </div>

      <div class="switch">
        <div class="left">
          <div class="name">启用三段键后端</div>
          <div class="desc">关闭后不处理三段键事件。</div>
        </div>
        <label class="toggle">
          <input id="BACKEND_ENABLE" type="checkbox">
          <span class="slider"></span>
        </label>
      </div>

      <div class="switch">
        <div class="left">
          <div class="name">启用音量键动作</div>
          <div class="desc">关闭后不处理音量键自定义动作，并停止音量键服务。</div>
        </div>
        <label class="toggle">
          <input id="VOLUME_KEY_ENABLE" type="checkbox">
          <span class="slider"></span>
        </label>
      </div>

      <div class="switch">
        <div class="left">
          <div class="name">音量键守护 / 屏蔽原始音量</div>
          <div class="desc">开启后单击执行动作时不改变音量，长按时恢复正常连续调音量。</div>
        </div>
        <label class="toggle">
          <input id="BLOCK_VOLUME_KEY" type="checkbox">
          <span class="slider"></span>
        </label>
      </div>

      <div class="field">
        <label class="label">轮询间隔</label>
        <input id="POLL_INTERVAL" class="input" type="text" placeholder="0.5">
      </div>
    </div>

    <div class="card">
      <h3>三段键设置</h3>

      <div class="field">
        <label class="label">Settings 命名空间</label>
        <input id="SLIDER_SETTINGS_NS" class="input" type="text">
      </div>

      <div class="field">
        <label class="label">Settings 键名</label>
        <input id="SLIDER_SETTINGS_KEY" class="input" type="text">
      </div>

      <div class="grid">
        <div class="field">
          <label class="label">上档值</label>
          <input id="VALUE_UP" class="input" type="text">
        </div>
        <div class="field">
          <label class="label">中档值</label>
          <input id="VALUE_MID" class="input" type="text">
        </div>
        <div class="field">
          <label class="label">下档值</label>
          <input id="VALUE_DOWN" class="input" type="text">
        </div>
      </div>
    </div>
  </div>

  <div id="page-actions" class="page">
    <div class="card">
      <h3>选择键位</h3>
      <div id="actionTabs" class="segment"></div>
    </div>

    <div class="card">
      <h3 id="actionTitle">动作配置</h3>

      <div class="field">
        <label class="label">动作类型</label>
        <select id="actionType" class="select"></select>
      </div>

      <div id="actionArgWrap" class="field hidden">
        <label id="actionArgLabel" class="label">动作参数</label>
        <input id="actionArg" class="input" type="text">
        <div id="actionArgHelp" class="help"></div>
      </div>

      <div id="appSuggestWrap" class="hidden">
        <div class="suggest" id="appSuggest"></div>
      </div>

      <div id="flashlightWrap" class="field hidden">
        <label class="label">手电筒模式</label>
        <select id="flashlightMode" class="select">
          <option value="toggle">切换</option>
          <option value="on">打开</option>
          <option value="off">关闭</option>
          <option value="level:1">亮度 1</option>
          <option value="level:2">亮度 2</option>
          <option value="level:3">亮度 3</option>
          <option value="level:4">亮度 4</option>
          <option value="level:5">亮度 5</option>
          <option value="custom-level">自定义亮度</option>
        </select>
        <div class="help">
          使用 Java CameraManager / TorchCtl 控制手电筒，不使用旧的 <code>cmd statusbar flashlight</code> 或 <code>service call flashlight</code>。
          亮度等级需要 Android 13+ 或设备相机 HAL 支持，不支持时后端会回退为普通打开。
        </div>
      </div>

      <div id="flashlightLevelWrap" class="field hidden">
        <label class="label">自定义亮度等级</label>
        <input id="flashlightLevel" class="input" type="number" inputmode="numeric" min="1" placeholder="例如 3">
        <div class="help">
          保存后参数为 <code>level:数字</code>，例如 <code>level:3</code>。
        </div>
      </div>

      <div id="shellWrap" class="field hidden">
        <label class="label">自定义 Shell</label>
        <textarea id="actionShell" class="textarea"></textarea>
      </div>
    </div>

    <div id="actionDefaultsCard" class="card defaults-card hidden">
      <h3>默认参数</h3>
      <div class="sub" id="actionDefaultsHint">当前动作可用的默认参数。</div>

      <div id="defaultPackageWrap" class="field hidden">
        <label class="label">默认包名</label>
        <input id="DEFAULT_PACKAGE" class="input" type="text" placeholder="com.tencent.mm">
        <div class="help">打开应用未填写包名时使用。</div>
      </div>

      <div id="defaultUrlWrap" class="field hidden">
        <label class="label">默认 URL</label>
        <input id="DEFAULT_URL" class="input" type="text" placeholder="https://">
        <div class="help">打开链接未填写地址时使用。</div>
      </div>

      <div id="wechatScanWrap" class="field hidden">
        <label class="label">微信扫一扫组件</label>
        <input id="WECHAT_SCAN_COMPONENT" class="input" type="text">
      </div>

      <div id="wechatPayWrap" class="field hidden">
        <label class="label">微信付款码组件</label>
        <input id="WECHAT_PAY_COMPONENT" class="input" type="text">
      </div>

      <div id="alipayScanWrap" class="field hidden">
        <label class="label">支付宝扫一扫组件</label>
        <input id="ALIPAY_SCAN_COMPONENT" class="input" type="text">
      </div>

      <div id="alipayScanUriWrap" class="field hidden">
        <label class="label">支付宝扫一扫 URI</label>
        <input id="ALIPAY_SCAN_URI" class="input" type="text">
      </div>

      <div id="alipayPayWrap" class="field hidden">
        <label class="label">支付宝付款码组件</label>
        <input id="ALIPAY_PAY_COMPONENT" class="input" type="text">
      </div>

      <div id="alipayPayUriWrap" class="field hidden">
        <label class="label">支付宝付款码 URI</label>
        <input id="ALIPAY_PAY_URI" class="input" type="text">
      </div>
    </div>
  </div>

  <div id="page-about" class="page">
    <div class="card">
      <h3>模块信息</h3>
      <div class="kv">
        <div>ID</div><div id="mod_id">--</div>
        <div>名称</div><div id="mod_name">--</div>
        <div>版本</div><div id="mod_version">--</div>
        <div>版本号</div><div id="mod_versionCode">--</div>
        <div>作者</div><div id="mod_author">--</div>
        <div>描述</div><div id="mod_desc">--</div>
      </div>

      <div class="link-list">
        <a id="coolapk_link_btn" class="link-btn hidden" href="#" target="_blank" rel="noopener">
          <span class="txt">酷安主页</span>
          <span class="tag">打开</span>
        </a>
        <a id="qq_group_link_btn" class="link-btn hidden" href="#" target="_blank" rel="noopener">
          <span class="txt">QQ群链接</span>
          <span class="tag">打开</span>
        </a>
        <div id="qq_group_box" class="link-btn hidden" style="cursor:default">
          <span class="txt" id="qq_group_text">QQ群</span>
          <span class="tag">复制</span>
        </div>
      </div>
    </div>
  </div>

  <div id="fabWrap" class="fab-wrap">
    <button id="fabMain1" class="fab primary hidden"></button>
    <button id="fabMain2" class="fab gray hidden"></button>
    <button id="fabMain3" class="fab gray hidden"></button>
  </div>

  <div id="toast" class="toast"></div>

<script>
const WEB_PORT = '__WEB_PORT__';
const state = {
  config:{},
  apps:[],
  appsLoaded:false,
  appsLoading:false,
  currentAction:'UP',
  statusTimer:null,
  currentTab:'home'
};

const actionDefs = [
  ['UP','中→上'],
  ['UP_RESET','上→中'],
  ['DOWN','中→下'],
  ['DOWN_RESET','下→中'],
  ['VOLUME_UP_CLICK','音量上单击'],
  ['VOLUME_UP_DOUBLE','音量上双击'],
  ['VOLUME_UP_LONG','音量上长按'],
  ['VOLUME_DOWN_CLICK','音量下单击'],
  ['VOLUME_DOWN_DOUBLE','音量下双击'],
  ['VOLUME_DOWN_LONG','音量下长按'],
  ['VOLUME_BOTH_CLICK','音量同时按']
];

function $(id){ return document.getElementById(id) }

function showToast(msg){
  const el=$('toast');
  el.textContent=msg||'已完成';
  el.classList.add('show');
  clearTimeout(showToast._t);
  showToast._t=setTimeout(()=>el.classList.remove('show'),2200);
}

function setBtnLoading(btn, loading, text){
  if(!btn) return;
  if(loading){
    if(!btn.dataset.text) btn.dataset.text = btn.textContent;
    btn.textContent = text || btn.textContent;
    btn.classList.add('loading');
    btn.disabled = true;
  }else{
    btn.classList.remove('loading');
    btn.disabled = false;
    btn.textContent = btn.dataset.text || btn.textContent;
  }
}

async function api(path, body){
  const opt = body===undefined ? {} : {
    method:'POST',
    headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body
  };
  const res = await fetch(`/cgi-bin/api/${path}`, opt);
  return await res.json();
}

function boolStr(v){
  return String(v)==='true' || String(v)==='1';
}

function setBadge(el, ok, onText='运行中', offText='未运行'){
  if(!el) return;
  el.className = 'badge ' + (ok ? 'ok' : 'off');
  el.textContent = ok ? onText : offText;
}

function updateModeTextFromConfig(cfg){
  const enable = boolStr(cfg.VOLUME_KEY_ENABLE);
  const block = boolStr(cfg.BLOCK_VOLUME_KEY);

  if(!enable){
    $('keyModeText').innerHTML = '<span class="badge off">已关闭</span>';
  }else if(enable && !block){
    $('keyModeText').innerHTML = '<span class="badge mid">动作 + 系统音量</span>';
  }else{
    $('keyModeText').innerHTML = '<span class="badge ok">守护拦截模式</span>';
  }
}

async function loadStatusOnly(showMsg=false){
  const data = await api('status');
  setBadge($('backendBadge'), !!data.backend_running);
  setBadge($('keydBadge'), !!data.keyd_running);
  $('sliderValueText').textContent = data.slider_value || '--';
  updateModeTextFromConfig(data.config || state.config || {});
  if(showMsg) showToast('状态已刷新');
}

function fillConfig(cfg){
  state.config = JSON.parse(JSON.stringify(cfg || {}));

  const textKeys = [
    'WEB_PORT','SLIDER_SETTINGS_NS','SLIDER_SETTINGS_KEY','VALUE_UP','VALUE_MID','VALUE_DOWN',
    'POLL_INTERVAL','DEFAULT_PACKAGE','DEFAULT_URL',
    'WECHAT_SCAN_COMPONENT','WECHAT_PAY_COMPONENT',
    'ALIPAY_SCAN_COMPONENT','ALIPAY_PAY_COMPONENT',
    'ALIPAY_SCAN_URI','ALIPAY_PAY_URI'
  ];

  textKeys.forEach(k=>{
    const el=$(k);
    if(el) el.value = cfg[k] ?? '';
  });

  if($('WEB_PORT') && !$('WEB_PORT').value){
    $('WEB_PORT').value = WEB_PORT || '8777';
  }

  if($('mod_web_port')){
    $('mod_web_port').textContent = cfg.WEB_PORT || WEB_PORT || '8777';
  }

  $('BACKEND_ENABLE').checked = boolStr(cfg.BACKEND_ENABLE);
  $('VOLUME_KEY_ENABLE').checked = boolStr(cfg.VOLUME_KEY_ENABLE);
  $('BLOCK_VOLUME_KEY').checked = boolStr(cfg.BLOCK_VOLUME_KEY);

  updateModeTextFromConfig(cfg);
  renderHomeActionOverview();
}

async function loadConfig(showMsg=false){
  const data = await api('status');
  fillConfig(data.config || {});
  if(showMsg) showToast('已重新读取当前配置');
  renderActionEditor();
}

function collectBaseConfig(){
  return {
    WEB_PORT:$('WEB_PORT').value.trim(),
    BACKEND_ENABLE:$('BACKEND_ENABLE').checked ? 'true' : 'false',
    SLIDER_SETTINGS_NS:$('SLIDER_SETTINGS_NS').value.trim(),
    SLIDER_SETTINGS_KEY:$('SLIDER_SETTINGS_KEY').value.trim(),
    VALUE_UP:$('VALUE_UP').value.trim(),
    VALUE_MID:$('VALUE_MID').value.trim(),
    VALUE_DOWN:$('VALUE_DOWN').value.trim(),
    POLL_INTERVAL:$('POLL_INTERVAL').value.trim(),
    VOLUME_KEY_ENABLE:$('VOLUME_KEY_ENABLE').checked ? 'true' : 'false',
    BLOCK_VOLUME_KEY:$('BLOCK_VOLUME_KEY').checked ? 'true' : 'false',
    DEFAULT_PACKAGE:$('DEFAULT_PACKAGE').value.trim(),
    DEFAULT_URL:$('DEFAULT_URL').value.trim(),
    WECHAT_SCAN_COMPONENT:$('WECHAT_SCAN_COMPONENT').value.trim(),
    WECHAT_PAY_COMPONENT:$('WECHAT_PAY_COMPONENT').value.trim(),
    ALIPAY_SCAN_COMPONENT:$('ALIPAY_SCAN_COMPONENT').value.trim(),
    ALIPAY_PAY_COMPONENT:$('ALIPAY_PAY_COMPONENT').value.trim(),
    ALIPAY_SCAN_URI:$('ALIPAY_SCAN_URI').value.trim(),
    ALIPAY_PAY_URI:$('ALIPAY_PAY_URI').value.trim()
  };
}

function toForm(obj){
  const p = new URLSearchParams();
  Object.keys(obj).forEach(k=>p.append(k, obj[k] ?? ''));
  return p.toString();
}

async function saveBaseConfig(){
  const btn = $('fabMain1');

  try{
    setBtnLoading(btn, true, '保存中');

    const form = collectBaseConfig();
    const r = await api('save_config', toForm(form));

    if(String(form.BACKEND_ENABLE) === 'true'){
      await api('start_slider_backend', '');
    }else{
      await api('stop_slider_backend', '');
    }

    if(String(form.VOLUME_KEY_ENABLE) === 'true'){
      await api('start_keyd', '');
    }else{
      await api('stop_keyd', '');
    }

    showToast(r.message || '基础配置已保存');
    await loadConfig();
    await loadStatusOnly();
  }catch(e){
    showToast('保存失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

async function startServicesFromHome(){
  const btn = $('fabMain1');
  try{
    setBtnLoading(btn, true, '启动中');
    if(boolStr($('BACKEND_ENABLE')?.checked ? 'true' : state.config.BACKEND_ENABLE)){
      await api('start_slider_backend','');
    }
    if(boolStr($('VOLUME_KEY_ENABLE')?.checked ? 'true' : state.config.VOLUME_KEY_ENABLE)){
      await api('start_keyd','');
    }
    showToast('已发送启动命令');
    setTimeout(()=>loadStatusOnly(), 700);
  }catch(e){
    showToast('启动失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

async function stopServicesFromHome(){
  const btn = $('fabMain2');
  try{
    setBtnLoading(btn, true, '停止中');
    await api('stop_slider_backend','');
    await api('stop_keyd','');
    showToast('已停止相关服务');
    setTimeout(()=>loadStatusOnly(), 500);
  }catch(e){
    showToast('停止失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

function buildActionTabs(){
  $('actionTabs').innerHTML = actionDefs.map(([k, title]) =>
    `<button class="${state.currentAction===k?'active':''}" onclick="switchAction('${k}')">${title}</button>`
  ).join('');
}

function switchAction(eventName){
  persistCurrentActionForm();
  state.currentAction = eventName;
  buildActionTabs();
  renderActionEditor();
}

function actionTypeList(){
  return [
    ['0','无动作'],
    ['1','自定义 Shell'],
    ['2','微信扫一扫'],
    ['3','微信付款码'],
    ['4','支付宝扫一扫'],
    ['5','支付宝付款码'],
    ['6','打开应用'],
    ['7','打开链接'],
    ['8','手电筒']
  ];
}

function actionTypeName(type){
  const hit = actionTypeList().find(x => x[0] === String(type));
  return hit ? hit[1] : '无动作';
}

function flashlightModeText(arg){
  arg = String(arg || 'toggle');

  const modeMap = {
    toggle:'切换',
    on:'打开',
    off:'关闭',
    'level:1':'亮度 1',
    'level:2':'亮度 2',
    'level:3':'亮度 3',
    'level:4':'亮度 4',
    'level:5':'亮度 5'
  };

  if(modeMap[arg]) return modeMap[arg];

  if(arg.startsWith('level:')){
    const lv = arg.slice('level:'.length);
    return lv ? `亮度 ${lv}` : '亮度 1';
  }

  return '切换';
}

function actionDisplayText(eventName){
  ensureActionDefaults(eventName);

  const type = String(state.config[`ACTION_${eventName}_TYPE`] ?? '0');
  const arg = state.config[`ACTION_${eventName}_ARG`] ?? '';

  if(type === '0') return '无';
  if(type === '1') return '自定义 Shell';
  if(type === '6') return arg ? `打开应用：${arg}` : '打开应用';
  if(type === '7') return arg ? `打开链接：${arg}` : '打开链接';
  if(type === '8') return `手电筒：${flashlightModeText(arg)}`;

  return actionTypeName(type);
}

function renderHomeActionOverview(){
  const box = $('homeActionOverview');
  if(!box) return;

  box.innerHTML = actionDefs.map(([eventName, title]) => `
    <div class="action-row">
      <div class="key">${escapeHtml(title)}</div>
      <div class="act">${escapeHtml(actionDisplayText(eventName))}</div>
    </div>
  `).join('');
}

function ensureActionDefaults(eventName){
  if(state.config[`ACTION_${eventName}_TYPE`] == null) state.config[`ACTION_${eventName}_TYPE`] = '0';
  if(state.config[`ACTION_${eventName}_ARG`] == null) state.config[`ACTION_${eventName}_ARG`] = '';
  if(state.config[`ACTION_${eventName}_SHELL`] == null) state.config[`ACTION_${eventName}_SHELL`] = '#!/system/bin/sh\n# 在这里写自定义 shell';
}

function renderActionEditor(){
  const ev = state.currentAction;
  ensureActionDefaults(ev);

  $('actionTitle').textContent = actionDefs.find(x=>x[0]===ev)?.[1] || ev;

  $('actionType').innerHTML = actionTypeList().map(([v,t]) =>
    `<option value="${v}" ${String(state.config[`ACTION_${ev}_TYPE`])===v?'selected':''}>${t}</option>`
  ).join('');

  $('actionArg').value = state.config[`ACTION_${ev}_ARG`] ?? '';
  $('actionShell').value = state.config[`ACTION_${ev}_SHELL`] ?? '#!/system/bin/sh\n# 在这里写自定义 shell';

  updateActionSubFields();
  buildActionTabs();
}

function readFlashlightArgFromForm(){
  const mode = $('flashlightMode')?.value || 'toggle';

  if(mode === 'custom-level'){
    const raw = String($('flashlightLevel')?.value || '').trim();
    const lv = raw && Number(raw) > 0 ? raw : '1';
    return `level:${lv}`;
  }

  return mode;
}

function persistCurrentActionForm(){
  const ev = state.currentAction;
  if(!ev) return;

  const type = $('actionType')?.value ?? '0';
  state.config[`ACTION_${ev}_TYPE`] = type;

  if(type === '1'){
    state.config[`ACTION_${ev}_SHELL`] = $('actionShell').value ?? '';
    state.config[`ACTION_${ev}_ARG`] = '';
  } else if(type === '8'){
    state.config[`ACTION_${ev}_ARG`] = readFlashlightArgFromForm();
  } else {
    state.config[`ACTION_${ev}_ARG`] = $('actionArg').value ?? '';
  }
}

function updateActionSubFields(){
  const ev = state.currentAction;
  const type = $('actionType').value;

  $('actionArgWrap').classList.add('hidden');
  $('shellWrap').classList.add('hidden');
  $('flashlightWrap').classList.add('hidden');
  $('flashlightLevelWrap')?.classList.add('hidden');
  $('appSuggestWrap').classList.add('hidden');

  $('actionArgLabel').textContent = '动作参数';
  $('actionArgHelp').textContent = '';

  if(type === '1'){
    $('shellWrap').classList.remove('hidden');
  } else if(type === '6'){
    $('actionArgWrap').classList.remove('hidden');
    $('appSuggestWrap').classList.remove('hidden');
    $('actionArgLabel').textContent = '应用包名';
    $('actionArgHelp').textContent = '输入包名会自动模糊匹配。留空时使用下方默认包名。';
    renderAppSuggest($('actionArg').value || '');
  } else if(type === '7'){
    $('actionArgWrap').classList.remove('hidden');
    $('actionArgLabel').textContent = '链接地址';
    $('actionArgHelp').textContent = '例如 https://example.com，留空时使用下方默认 URL。';
  } else if(type === '8'){
    $('flashlightWrap').classList.remove('hidden');

    const arg = String(state.config[`ACTION_${ev}_ARG`] || 'toggle');
    const presetValues = [
      'toggle',
      'on',
      'off',
      'level:1',
      'level:2',
      'level:3',
      'level:4',
      'level:5'
    ];

    if(presetValues.includes(arg)){
      $('flashlightMode').value = arg;
      $('flashlightLevelWrap')?.classList.add('hidden');
      if($('flashlightLevel')) $('flashlightLevel').value = '';
    }else if(arg.startsWith('level:')){
      $('flashlightMode').value = 'custom-level';
      $('flashlightLevelWrap')?.classList.remove('hidden');
      if($('flashlightLevel')){
        $('flashlightLevel').value = arg.slice('level:'.length) || '1';
      }
    }else{
      $('flashlightMode').value = 'toggle';
      $('flashlightLevelWrap')?.classList.add('hidden');
      if($('flashlightLevel')) $('flashlightLevel').value = '';
    }
  }

  renderActionDefaults();
}

function renderActionDefaults(){
  const type = $('actionType').value;

  const card = $('actionDefaultsCard');
  const wraps = [
    'defaultPackageWrap',
    'defaultUrlWrap',
    'wechatScanWrap',
    'wechatPayWrap',
    'alipayScanWrap',
    'alipayScanUriWrap',
    'alipayPayWrap',
    'alipayPayUriWrap'
  ];

  wraps.forEach(id => $(id)?.classList.add('hidden'));
  card.classList.add('hidden');

  if(type === '2'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '微信扫一扫使用的组件，启动失败时会回退到打开微信。';
    $('wechatScanWrap').classList.remove('hidden');
  } else if(type === '3'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '微信付款码使用的组件，启动失败时会回退到打开微信。';
    $('wechatPayWrap').classList.remove('hidden');
  } else if(type === '4'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '支付宝扫一扫优先使用组件，组件为空或失败时使用 URI。';
    $('alipayScanWrap').classList.remove('hidden');
    $('alipayScanUriWrap').classList.remove('hidden');
  } else if(type === '5'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '支付宝付款码优先使用组件，组件为空或失败时使用 URI。';
    $('alipayPayWrap').classList.remove('hidden');
    $('alipayPayUriWrap').classList.remove('hidden');
  } else if(type === '6'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '当前动作参数为空时，会使用默认包名。';
    $('defaultPackageWrap').classList.remove('hidden');
  } else if(type === '7'){
    card.classList.remove('hidden');
    $('actionDefaultsHint').textContent = '当前动作参数为空时，会使用默认 URL。';
    $('defaultUrlWrap').classList.remove('hidden');
  }
}

function collectActionDefaultConfig(){
  const keys = [
    'DEFAULT_PACKAGE',
    'DEFAULT_URL',
    'WECHAT_SCAN_COMPONENT',
    'WECHAT_PAY_COMPONENT',
    'ALIPAY_SCAN_COMPONENT',
    'ALIPAY_PAY_COMPONENT',
    'ALIPAY_SCAN_URI',
    'ALIPAY_PAY_URI'
  ];

  const out = {};

  keys.forEach(k => {
    const el = $(k);
    if(el){
      out[k] = el.value.trim();
      state.config[k] = out[k];
    }
  });

  return out;
}

async function testCurrentActionDraft(){
  const btn = $('fabMain1');
  try{
    setBtnLoading(btn, true, '测试中');
    persistCurrentActionForm();

    const ev = state.currentAction;
    ensureActionDefaults(ev);

    const payload = {
      event: ev,
      type: state.config[`ACTION_${ev}_TYPE`] ?? '0',
      arg: state.config[`ACTION_${ev}_ARG`] ?? '',
      shell: state.config[`ACTION_${ev}_SHELL`] ?? ''
    };

    const r = await api('test_action_draft', toForm(payload));
    showToast(r.message || '已测试（未保存）');
  }catch(e){
    showToast('测试失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

async function saveCurrentAction(){
  const btn = $('fabMain2');
  try{
    setBtnLoading(btn, true, '保存中');
    persistCurrentActionForm();

    const ev = state.currentAction;
    ensureActionDefaults(ev);

    const payload = collectActionDefaultConfig();
    payload[`ACTION_${ev}_TYPE`] = state.config[`ACTION_${ev}_TYPE`] ?? '0';
    payload[`ACTION_${ev}_ARG`] = state.config[`ACTION_${ev}_ARG`] ?? '';
    payload[`ACTION_${ev}_SHELL`] = state.config[`ACTION_${ev}_SHELL`] ?? '';

    const r = await api('save_config', toForm(payload));
    const actionType = String(payload[`ACTION_${ev}_TYPE`] ?? '0');
    const isVolumeAction = ev.startsWith('VOLUME_');
    let autoEnabled = false;
    let backendStarted = false;
    if(isVolumeAction && actionType !== '0' && !boolStr(state.config.VOLUME_KEY_ENABLE)){
      await api('save_config', toForm({VOLUME_KEY_ENABLE:'true'}));
      await api('start_keyd', '');
      autoEnabled = true;
    }
    if(!isVolumeAction && actionType !== '0' && boolStr(state.config.BACKEND_ENABLE)){
      await api('start_slider_backend', '');
      backendStarted = true;
    }
    let message = r.message || `已保存 ${ev}`;
    if(autoEnabled) message += '，并已启用音量键服务';
    if(backendStarted) message += '，三段键后端已启动';
    showToast(message);
    await loadConfig();
    renderHomeActionOverview();
  }catch(e){
    showToast('保存当前键位失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

async function restoreCurrentAction(){
  const btn = $('fabMain3');
  try{
    setBtnLoading(btn, true, '还原中');
    await loadConfig();
    renderActionEditor();
    showToast('已还原当前键位');
  }catch(e){
    showToast('还原失败');
  }finally{
    setBtnLoading(btn, false);
  }
}

async function loadApps(force=false){
  if((state.appsLoaded || state.appsLoading) && !force) return;

  state.appsLoading = true;
  try{
    const r = await api('apps');
    state.apps = Array.isArray(r.apps) ? r.apps : [];
    state.appsLoaded = true;
  }catch(e){
    state.apps = [];
    state.appsLoaded = false;
    showToast('应用列表加载失败');
  }finally{
    state.appsLoading = false;
  }
}

function renderAppSuggest(keyword){
  const box = $('appSuggest');
  const q = (keyword || '').trim().toLowerCase();

  if(state.appsLoading){
    box.innerHTML = '<div class="help">应用列表加载中…</div>';
    return;
  }

  let list = state.apps || [];
  if(q){
    list = list.filter(app =>
      String(app.package || '').toLowerCase().includes(q) ||
      String(app.name || '').toLowerCase().includes(q)
    );
  }

  list = list.slice(0, 24);

  box.innerHTML = list.map(app => `
    <div class="app-item" onclick="chooseApp('${escapeJs(app.package || '')}')">
      <div class="meta">
        <div class="name">${escapeHtml(app.name || app.package || '')}</div>
        <div class="pkg">${escapeHtml(app.package || '')}</div>
      </div>
    </div>
  `).join('') || '<div class="help">没有匹配到应用</div>';
}

function chooseApp(pkg){
  $('actionArg').value = pkg;
  state.config[`ACTION_${state.currentAction}_ARG`] = pkg;
  showToast('已选择应用：' + pkg);
}

function setLinkButton(id, url, text){
  const el = $(id);
  if(!el) return;

  if(url){
    el.href = url;
    el.querySelector('.txt').textContent = text || url;
    el.classList.remove('hidden');
  }else{
    el.classList.add('hidden');
  }
}

async function loadModuleInfo(){
  try{
    const r = await api('module_info');
    $('mod_id').textContent = r.id || '--';
    $('mod_name').textContent = r.name || '--';
    $('mod_version').textContent = r.version || '--';
    $('mod_versionCode').textContent = r.versionCode || '--';
    $('mod_author').textContent = r.author || '--';
    $('mod_desc').textContent = r.description || '--';

    if($('mod_web_port')){
    $('mod_web_port').textContent = state.config.WEB_PORT || WEB_PORT || '8777';
  }

    setLinkButton('coolapk_link_btn', r.coolapk || '', '酷安主页');
    setLinkButton('qq_group_link_btn', r.qq_group_link || '', 'QQ群链接');

    if(r.qq_group){
      $('qq_group_text').textContent = 'QQ群：' + r.qq_group;
      $('qq_group_box').classList.remove('hidden');
    }else{
      $('qq_group_box').classList.add('hidden');
    }
  }catch(e){}
}

function updateFab(){
  const b1 = $('fabMain1');
  const b2 = $('fabMain2');
  const b3 = $('fabMain3');

  [b1, b2, b3].forEach(btn => {
    if(!btn) return;
    btn.classList.add('hidden');
    btn.className = 'fab gray hidden';
    btn.onclick = null;
  });

  if(state.currentTab === 'home'){
    b1.textContent = '启动服务';
    b1.className = 'fab green';
    b1.onclick = startServicesFromHome;

    b2.textContent = '停止服务';
    b2.className = 'fab red';
    b2.onclick = stopServicesFromHome;
  } else if(state.currentTab === 'config'){
    b1.textContent = '保存配置';
    b1.className = 'fab primary';
    b1.onclick = saveBaseConfig;

    b2.textContent = '还原当前';
    b2.className = 'fab gray';
    b2.onclick = () => loadConfig(true);
  } else if(state.currentTab === 'actions'){
    b1.textContent = '测试草稿';
    b1.className = 'fab gray';
    b1.onclick = testCurrentActionDraft;

    b2.textContent = '保存键位';
    b2.className = 'fab primary';
    b2.onclick = saveCurrentAction;

    b3.textContent = '还原键位';
    b3.className = 'fab orange';
    b3.onclick = restoreCurrentAction;
  }
}

function escapeHtml(s){
  return String(s ?? '')
    .replaceAll('&','&amp;')
    .replaceAll('<','&lt;')
    .replaceAll('>','&gt;')
    .replaceAll('"','&quot;');
}

function escapeJs(s){
  return String(s ?? '').replaceAll('\\','\\\\').replaceAll("'","\\'");
}

document.querySelectorAll('.tab').forEach(btn=>{
  btn.addEventListener('click', async ()=>{
    document.querySelectorAll('.tab').forEach(x=>x.classList.remove('active'));
    document.querySelectorAll('.page').forEach(x=>x.classList.remove('active'));
    btn.classList.add('active');
    $('page-'+btn.dataset.tab).classList.add('active');

    state.currentTab = btn.dataset.tab;
    updateFab();

    if(btn.dataset.tab === 'actions'){
      renderActionEditor();
    }
    if(btn.dataset.tab === 'about'){
      await loadModuleInfo();
    }
  });
});

$('actionType').addEventListener('change', ()=>{
  state.config[`ACTION_${state.currentAction}_TYPE`] = $('actionType').value;
  updateActionSubFields();
});

$('actionArg').addEventListener('input', ()=>{
  const type = $('actionType').value;
  state.config[`ACTION_${state.currentAction}_ARG`] = $('actionArg').value;
  if(type === '6'){
    renderAppSuggest($('actionArg').value || '');
  }
});

$('flashlightMode').addEventListener('change', ()=>{
  const mode = $('flashlightMode').value || 'toggle';

  if(mode === 'custom-level'){
    $('flashlightLevelWrap')?.classList.remove('hidden');

    const lv = String($('flashlightLevel')?.value || '').trim() || '1';
    state.config[`ACTION_${state.currentAction}_ARG`] = `level:${lv}`;
  }else{
    $('flashlightLevelWrap')?.classList.add('hidden');
    state.config[`ACTION_${state.currentAction}_ARG`] = mode;
  }
});

$('flashlightLevel')?.addEventListener('input', ()=>{
  const mode = $('flashlightMode').value || 'toggle';

  if(mode === 'custom-level'){
    const raw = String($('flashlightLevel').value || '').trim();
    const lv = raw && Number(raw) > 0 ? raw : '1';
    state.config[`ACTION_${state.currentAction}_ARG`] = `level:${lv}`;
  }
});

$('actionShell').addEventListener('input', ()=>{
  state.config[`ACTION_${state.currentAction}_SHELL`] = $('actionShell').value;
});

$('qq_group_box').addEventListener('click', async ()=>{
  const text = $('qq_group_text').textContent.replace('QQ群：','');
  try{
    await navigator.clipboard.writeText(text);
    showToast('QQ群号已复制');
  }catch(e){
    showToast(text);
  }
});

(async function init(){
  buildActionTabs();
  await loadConfig();
  await loadStatusOnly();
  loadApps();
  renderHomeActionOverview();
  state.currentTab = 'home';
  updateFab();
  state.statusTimer = setInterval(()=>{
    if(!document.hidden) loadStatusOnly();
  }, 15000);
  document.addEventListener('visibilitychange', ()=>{
    if(!document.hidden) loadStatusOnly();
  });
})();
</script>
</body>
</html>
