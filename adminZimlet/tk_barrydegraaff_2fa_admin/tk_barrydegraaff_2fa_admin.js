/*
Copyright (C) 2014-2019  Barry de Graaff

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
 */

// /opt/zimbra/jetty_base/webapps/zimbraAdmin/js/zimbraAdmin/accounts/view/ZaAccountXFormView.js

try {
   ZaAccountXFormView.isAuthfromInternal =
   function(acctName) {
     return true;
   }
}   
catch(error)
{
   setTimeout(function(){ 
      ZaAccountXFormView.isAuthfromInternal =
      function(acctName) {
        return true;
      }      
   }, 3000);
};   
   
