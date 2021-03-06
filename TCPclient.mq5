//+------------------------------------------------------------------+
//|                                                    TCPclient.mq5 |
//|                                    André Augusto Giannotti Scotá |
//|                              https://sites.google.com/view/a2gs/ |
//+------------------------------------------------------------------+

#define NETWORK_BUFFER_SIZE (1000)

input string address     = "localhost";
input uint   port        = 9998;
input uint   timeout     = 10000; // Connection timeout
input uint   readtimeout = 5000; // Read from server timeout
input string msgSend     = "abc123"; // Message to send to server
input uint   msgSendSz   = 3; // Total bytes of message to send (0 or abouve message size = all bytes)
input uint   msgRecvSz   = 3; // Total bytes to read from server per time (just once for this sample)
input bool   DEBUG       = true;

void OnInit(void)
{
   if(DEBUG == true) Print("Initializing.");

   int socket = SocketCreate();

   if(socket == INVALID_HANDLE){
      printf("Error creating socket [%d].", GetLastError());
      return;
   }

   if(DEBUG == true) Print("Trying connection.");

   if(SocketConnect(socket, address, port, timeout) == true){
      int sendLen = 0, recvLen = 0;
      char sendMsg[];
      char recvMsg[];

      if(DEBUG == true) Print("Connected.");
      
      /* https://www.mql5.com/en/docs/network/sockettimeouts
      if(SocketTimeouts(socket, 0, 0) == false){
         Print("Error setting socket timeouts: [%d]", GetLastError());
         return;
      }
      */
      
      ArrayInitialize(sendMsg, '\0');
      ArrayInitialize(recvMsg, '\0');
      
      if(ArrayResize(sendMsg, NETWORK_BUFFER_SIZE, 1) == -1){
         Print("Array resizing the buffer send error.");
         ArrayFree(sendMsg); ArrayFree(recvMsg); SocketClose(socket); ExpertRemove();
         return;
      }

      if(ArrayResize(recvMsg, NETWORK_BUFFER_SIZE, 1) == -1){
         Print("Array resizing the buffer recv error.");
         ArrayFree(sendMsg); ArrayFree(recvMsg); SocketClose(socket); ExpertRemove();
         return;
      }
      
      ArrayFill(sendMsg, 0, NETWORK_BUFFER_SIZE, '\0');
      ArrayFill(recvMsg, 0, NETWORK_BUFFER_SIZE, '\0');
      
      if((msgSendSz <= 0) || (msgSendSz > (uint)StringLen(msgSend)))
         sendLen = StringLen(msgSend);
      else
         sendLen = (int)msgSendSz;

      int convLen = StringToCharArray(msgSend, sendMsg, 0, sendLen);

      if(DEBUG == true){
         printf("Sending [%d] bytes of a [%d] total. Message:", sendLen, convLen);
         ArrayPrint(sendMsg, 0, " ", 0, convLen, 0);
      }

      sendLen = SocketSend(socket, sendMsg, convLen);
      if(sendLen == -1){
         printf("Sending socket error: [%d].", GetLastError());
         ArrayFree(sendMsg); ArrayFree(recvMsg); SocketClose(socket); ExpertRemove();
         return;
      }

      recvLen = SocketRead(socket, recvMsg, msgRecvSz, readtimeout);
      if(recvLen == -1){
         printf("Reading socket error: [%d].", GetLastError());
         ArrayFree(sendMsg); ArrayFree(recvMsg); SocketClose(socket); ExpertRemove();
         return;
      }

      if(DEBUG == true){
         printf("Receive: [%d]. Message:", recvLen);
         ArrayPrint(recvMsg, 0, " ", 0, recvLen, 0);
      }
      
      uint remainingBytes = 0;
      remainingBytes = SocketIsReadable(socket);
      if(remainingBytes != 0){
         printf("There are [%d] bytes remaining to be read.", remainingBytes);
      }

      ArrayFree(sendMsg); ArrayFree(recvMsg);

   }else{
      printf("Connection error: [%d]\n", GetLastError());
   }

   if(SocketIsConnected(socket) == true){
      Print("Close connection.");
      SocketClose(socket);
   }
   
   ExpertRemove();
}