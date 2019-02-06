/*
Copyright (C) 2017-2019  Barry de Graaff

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
*/

function tk_barrydegraaff_2fa_HandlerObject() {
   tk_barrydegraaff_2fa_HandlerObject.settings = {};
};

tk_barrydegraaff_2fa_HandlerObject.prototype = new ZmZimletBase();
tk_barrydegraaff_2fa_HandlerObject.prototype.constructor = tk_barrydegraaff_2fa_HandlerObject;
var TwoFaZimlet = tk_barrydegraaff_2fa_HandlerObject;

TwoFaZimlet.prototype.init = function () {
   try {
      var section = {
         title: '2FA Account Security',
         icon: 'tk_barrydegraaff_2fa-panelIcon',
         //templateId: 'tk_barrydegraaff_2fa.templates.preferences' + '#Preferences',
         priority: 49,
         manageDirty: true,
         prefs: [
            'MySetting',
         ],
         createView: function(parent, sectionObj, controller) {
            return new TwoFaZimletPrefs(parent, sectionObj, controller, appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject);
         }
      };
      ZmPref.registerPrefSection('2FA_PREFERENCES', section);
   } catch (exception)
   {
      TwoFaZimlet.prototype.displayError('2FA Zimlet Initialization error occurred',window.btoa(exception),'2FA Zimlet Initialization error occurred');
   }   
};

/* status method show a Zimbra status message
* */
TwoFaZimlet.prototype.status = function(text, type) {
   var transitions = [ ZmToast.FADE_IN, ZmToast.PAUSE, ZmToast.FADE_OUT ];
   appCtxt.getAppController().setStatusMsg(text, type, null, transitions);
}; 

TwoFaZimlet.prototype._cancelBtn =
function() {
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   
   try{
      zimletInstance._dialog.setContent('');
      zimletInstance._dialog.popdown();
   }
   catch (err) {}
};

TwoFaZimletPrefs = function(shell, section, controller, handler) {
   if (!arguments.length) return;
   this._createHtml = function(){return document.createTextNode("");};
   
   this.getHtmlElement = function()
   {
      g = document.createElement('div');
      g.setAttribute("id", "tk_barrydegraaff_2fa_prefscreen");
      g.setAttribute("class", "ZmPreferencesPage ZWidget");
      return g;
   };
   
   this.setScrollStyle = function(){return 'none';};

   this.hideMe = function()
   {
      document.getElementById('tk_barrydegraaff_2fa_prefscreen').style='display:none';
      document.getElementById('zb__PREF__SAVE').style='display:block';
      return;
   };
   this.resetSize = function()   
   {       
      var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
      zimletInstance.resize();      
   };
   this.setVisible = function(){return;};
   
   this.showMe = function()
   {
      TwoFaZimlet.prototype.showMeImpl();
   };
   
   this.getTabGroupMember = function(){return;};
   this.hasResetButton = function(){return false;};
   this.getTitle = function(){return '2FA Account Security';};
   
   this._handler = handler;
   ZmPreferencesPage.call(this, shell, section, controller);
};

TwoFaZimlet.prototype.resize = function()
{
   try {
      var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
      zimletInstance.appHeight = (Math.max( document.body.scrollHeight, document.body.offsetHeight, document.documentElement.clientHeight, document.documentElement.scrollHeight, document.documentElement.offsetHeight )-110 );         
      document.getElementById('tk_barrydegraaff_2fa_prefscreen').style='display:block; overflow-y: scroll !important; max-height:'+zimletInstance.appHeight+'px !important';
   }
   catch(err)   
   {
   }
   return;
};   

TwoFaZimlet.prototype.showMeImpl = function()
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   zimletInstance.resize();
   try{
      zimletInstance._dialog.setContent('');
      zimletInstance._dialog.popdown();
   }
   catch (err) {} 
   document.getElementById('zb__PREF__SAVE').style='display:none';
   document.title = "Zimbra: " + ZmMsg.preferences +": 2FA Account Security";   
   document.getElementById('tk_barrydegraaff_2fa_prefscreen').innerHTML = "<h2 class='prefHeader'>Two Factor Authentication Setup</h2><img style='width:50px; height:auto; float:left' src='"+zimletInstance.getResource('2fa-logo.png')+"'>Two Factor Authentication adds additional security to your account by requiring not only your username and password, but also a code from your smart phone. <br>This added level of security makes it much more difficult for your account to be compromised by an intruder.<br><br><h2 class='prefHeader'>Add new tokens</h2>First install one of the following apps on your mobile: <ul><li><a href='https://itunes.apple.com/us/app/authenticator/id766157276' target='_blank'>Authenticator for iPhone</a></li><li><a href='https://play.google.com/store/apps/details?id=org.fedorahosted.freeotp' target='_blank'>FreeOTP Authenticator for Android</a></li></ul><br><button id='2faSetupBtn' onclick='TwoFaZimlet.prototype.getQR()'>Click here to continue setup</button><h2 class='prefHeader'>Add app passcode</h2>Here you can generate passcodes for apps that do not support Two Factor Authentication.<br>This can be your email app on your phone or the email client on your laptop (Outlook/Thunderbird).<br><br><button id='2faSetupBtn' onclick='TwoFaZimlet.prototype.getAppPasscode()'>Create App passcode</button><div id='tk_barrydegraaff_2fa_prefscreen_qrcode'></div><h2 class='prefHeader'>Current tokens</h2><div id='tk_barrydegraaff_2fa_currentTokens'><img id='2facode' src=''>Here you can <b>remove</b> your existing tokens.<br><br></div>";

   var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
   var params = {
      soapDoc: soapDoc,
      asyncMode: true,
      callback:TwoFaZimlet.prototype.displayTokens
   };
   soapDoc.getMethod().setAttribute("action", "PIList");
   appCtxt.getAppController().sendRequest(params);

   return;   
};

TwoFaZimlet.prototype.getAppPasscode = function()
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   zimletInstance._dialog = new ZmDialog( { title:"Please enter token description", parent:zimletInstance.getShell(), standardButtons:[DwtDialog.OK_BUTTON], disposeOnPopDown:true } );   
   
   zimletInstance._dialog.setContent(
   '<div style="width:450px; height:100px;">'+
   'Please enter a description for your new token. <br><br>If you are not sure, just enter your phone model name or application you want to use this token for. (Example: iPhone 7 or Outlook)<br><br>'+   
   '<div class="DwtInputField"><input id="zimbratokendescr" placeholder="'+ZmMsg.description+'"></div>' +
   '</div>'
   );
   
   zimletInstance._dialog.setButtonListener(DwtDialog.OK_BUTTON, new AjxListener(zimletInstance, zimletInstance.getAppPasscodewithDescr));
   zimletInstance._dialog.setEnterListener(new AjxListener(zimletInstance, zimletInstance.getAppPasscodewithDescr));
   document.getElementById(zimletInstance._dialog.__internalId+'_handle').style.backgroundColor = '#eeeeee';
   document.getElementById(zimletInstance._dialog.__internalId+'_title').style.textAlign = 'center';
   
   zimletInstance._dialog.popup(); 
   document.getElementById('zimbratokendescr').focus();    
};

TwoFaZimlet.prototype.getQR = function()
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   zimletInstance._dialog = new ZmDialog( { title:"Please enter token description", parent:zimletInstance.getShell(), standardButtons:[DwtDialog.OK_BUTTON], disposeOnPopDown:true } );   
   
   zimletInstance._dialog.setContent(
   '<div style="width:450px; height:450px;">'+
   'Please enter a description for your new token. <br><br>If you are not sure, just enter your phone model name or application you want to use this token for. (Example: iPhone 7 or Outlook)<br><br>'+   
   '<div class="DwtInputField"><input id="zimbratokendescr" placeholder="'+ZmMsg.description+'"></div>' +
   '</div>'
   );
   
   zimletInstance._dialog.setButtonListener(DwtDialog.OK_BUTTON, new AjxListener(zimletInstance, zimletInstance.getQRwithDescr));
   zimletInstance._dialog.setEnterListener(new AjxListener(zimletInstance, zimletInstance.getQRwithDescr));
   document.getElementById(zimletInstance._dialog.__internalId+'_handle').style.backgroundColor = '#eeeeee';
   document.getElementById(zimletInstance._dialog.__internalId+'_title').style.textAlign = 'center';
   
   zimletInstance._dialog.popup(); 
   document.getElementById('zimbratokendescr').focus();    
};

TwoFaZimlet.prototype.getQRwithDescr = function()
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
   var params = {
      soapDoc: soapDoc,
      asyncMode: true,
      callback:TwoFaZimlet.prototype.displayQR
   };
   soapDoc.getMethod().setAttribute("action", "PIInit");
   soapDoc.getMethod().setAttribute("zimbratokendescr", document.getElementById('zimbratokendescr').value);
   appCtxt.getAppController().sendRequest(params);      
};

TwoFaZimlet.prototype.getAppPasscodewithDescr = function()
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
   var params = {
      soapDoc: soapDoc,
      asyncMode: true,
      callback:TwoFaZimlet.prototype.displayAppPasscode
   };
   soapDoc.getMethod().setAttribute("action", "PIDeviceInit");
   soapDoc.getMethod().setAttribute("zimbratokendescr", document.getElementById('zimbratokendescr').value);
   appCtxt.getAppController().sendRequest(params);      
};

TwoFaZimlet.prototype.displayQR = function(args)
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   try {
      var imagedata = args._data.response._content;
      zimletInstance._dialog.setTitle('Scan this QR code using your phone');
      zimletInstance._dialog.setContent('<img src="'+imagedata+'" onerror="TwoFaZimlet.prototype.displayError(\'An application error occurred\',\''+  window.btoa(args._data.response._content)+'\',\'An application error occurred\')">');
      zimletInstance._dialog.setButtonListener(DwtDialog.OK_BUTTON, new AjxListener(zimletInstance, zimletInstance.showMeImpl));
      zimletInstance._dialog.setEnterListener(new AjxListener(zimletInstance, zimletInstance.showMeImpl));
      
   }
   catch (exception)
   {
      TwoFaZimlet.prototype.displayError('A Zimlet error occurred',window.btoa(exception),'A Zimlet error occurred');
   }
};

TwoFaZimlet.prototype.displayAppPasscode = function(args)
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   try {
      var data = JSON.parse(args._data.response._content);
      console.log();
      zimletInstance._dialog.setTitle('Enter your password followed by the code as password on your app');
      zimletInstance._dialog.setContent('Code: <input value="'+data.detail.otpkey.value.replace('seed://','')+'">');
      zimletInstance._dialog.setButtonListener(DwtDialog.OK_BUTTON, new AjxListener(zimletInstance, zimletInstance.showMeImpl));
      zimletInstance._dialog.setEnterListener(new AjxListener(zimletInstance, zimletInstance.showMeImpl));
      
   }
   catch (exception)
   {
      TwoFaZimlet.prototype.displayError('A Zimlet error occurred',window.btoa(exception),'A Zimlet error occurred');
   }
};
TwoFaZimlet.prototype.displayError = function(msg, data, title)
{
   var zimletInstance = appCtxt._zimletMgr.getZimletByName('tk_barrydegraaff_2fa').handlerObject;
   zimletInstance.displayErrorMessage(msg, window.atob(data), title);
};

TwoFaZimlet.prototype.displayTokens = function(args)
{
   try {
      var data = JSON.parse(args._data.response._content);
      console.log(data);
      var tokens = data.result.value.tokens;
      for (var i = 0; i < tokens.length; i++) {
         document.getElementById('tk_barrydegraaff_2fa_currentTokens').innerHTML += '<button title=\'Failcount: '+tokens[i].failcount+'\r\nLast used: '+(tokens[i].info.last_auth ? tokens[i].info.last_auth : 'never') +'\' onclick=\'TwoFaZimlet.prototype.deleteTokens("'+tokens[i].serial+'")\' style=\'width:200px;\' >'+tokens[i].serial+'<br>'+tokens[i].description+'</button><br>';
      }
   }
   catch (exception)
   {
      
   }
};

TwoFaZimlet.prototype.deleteTokens = function(serial)
{
   var soapDoc = AjxSoapDoc.create("privacyIdea", "urn:privacyIdea", null);
   var params = {
      soapDoc: soapDoc,
      asyncMode: true,
      callback:TwoFaZimlet.prototype.showMeImpl
   };
   soapDoc.getMethod().setAttribute("action", "PIDelete");
   soapDoc.getMethod().setAttribute("serial", serial);
   appCtxt.getAppController().sendRequest(params);
};
  
