//+------------------------------------------------------------------+
//|                                            TCPclient_httpTLS.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property script_show_inputs

input string Address= "www.mql5.com";
input int    Port   = 80;
input bool   ExtTLS = false;

bool isTLS = false;

void setTLSFlag(bool f)
{
   isTLS = f;
}

bool getTLSFlag(void)
{
   return(isTLS);
}

bool HTTPSend(int socket, string request)
{
   char req[];
   int  len = StringToCharArray(request, req) - 1;

   if(len < 0)
      return(false);

   /* if secure TLS connection is used via the port 443 */
   if(getTLSFlag())
      return(SocketTlsSend(socket, req, len) == len);

   /* if standard TCP connection is used */
   return(SocketSend(socket, req, len) == len);
}

bool HTTPRecv(int socket,uint timeout)
{
   char   rsp[];
   string result;
   uint   timeout_check = GetTickCount() + timeout;
   
   /* read data from sockets till they are still present but not longer than timeout */
   do{
      uint len = SocketIsReadable(socket);
   
      if(len){
         int rsp_len;
         
         /* various reading commands depending on whether the connection is secure or not */
         if(getTLSFlag())
            rsp_len = SocketTlsRead(socket, rsp, len);
         else
            rsp_len = SocketRead(socket, rsp, len, timeout);
         
         /* analyze the response */
         if(rsp_len > 0){
            result += CharArrayToString(rsp, 0, rsp_len);

            /* print only the response header */
            int header_end = StringFind(result, "\r\n\r\n");
            if(header_end > 0){
               printf("HTTP answer header received:");
               printf(StringSubstr(result, 0, header_end));
               return(true);
            }
         }
      }
   }while((GetTickCount() < timeout_check) && !(IsStopped()));

   return(false);
}

void OnInit(void)
{
   int socket = SocketCreate();
   
   setTLSFlag(false);

   /* check the handle */
   if(socket != INVALID_HANDLE){

      /* connect if all is well */
      if(SocketConnect(socket, Address, Port, 1000) == true){
         printf("Established connection to [%s:%d]", Address, Port);
         
         string   subject, issuer, serial, thumbprint;
         datetime expiration;

         /* if connection is secured by the certificate, display its data */
         if(SocketTlsCertificate(socket, subject, issuer, serial, thumbprint, expiration) == true){

            printf("TLS certificate:");
            printf("\tOwner.....: [%s]", subject);
            printf("\tIssuer....: [%s]", issuer);
            printf("\tNumber....: [%s]", serial);
            printf("\tPrint.....: [%s]", thumbprint);
            printf("\tExpiration: [%s]", TimeToString(expiration));

            setTLSFlag(true);
         }

         /* send GET request to the server */
         string getRequest = "GET / HTTP/1.1\r\nHost: www.mql5.com\r\n\r\n";

         /* https://httpbin.org/ip
         string getRequest = "GET /ip";
         */

         if(HTTPSend(socket, getRequest)){
            printf("GET request sent");
            /*--- read the response */
            if(!HTTPRecv(socket, 1000))
               printf("Failed to get a response, error: [%d]", GetLastError());
         }else
            printf("Failed to send GET request, error: [%d]", GetLastError());
      }else{
         printf("Connection to [%s:%d] failed, error: [%d]", Address, Port, GetLastError());
      }

      /* close a socket after using */
      SocketClose(socket);
   }else
     printf("Failed to create a socket, error: [%d]", GetLastError());
}