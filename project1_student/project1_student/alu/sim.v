`timescale 10ns / 1ns

module alu_test
();

	// TODO: implement your testbench
	 //long and short data wide
   parameter Short=4;
   parameter Long=32;
   parameter wide=Short;
   parameter ShortDataWide=5'b1_0000;
   parameter LongDataWide=33'b1_0000_0000_0000_0000_0000_0000_0000_0000;
   parameter MaxData=ShortDataWide;
    //time
   parameter c=2;// 1c is a whole clk 
   parameter OneOrderTime=MaxData*MaxData*c; //one ALU control order,run A(2^32)*
   parameter stoptime= 8*OneOrderTime; //five ALU control order
   //for alu model
   reg[wide-1:0] A,B;
   wire[2:0] ALUop;
   wire Overflow,CarryOut,Zero;
   wire[wide-1:0] Result;
   //other
   reg clk;
   reg[2:0] order[7:0];
   integer OrderNumber;
   //for check the add/sub result
   wire[wide-1:0] AddResult,SubResult;
   assign AddResult = A+B;
   assign SubResult = A-B;
   
   //file
   integer filew;
   //order
   parameter   And = 3'b000,//and
               Or  = 3'b001,//or
               Add = 3'b010,//add
			//新增////////////////////
			   Sltu= 3'b011,
			   Sll = 3'b100,
			   Lu  = 3'b101,
			//////////////////////////  
               Sub = 3'b110,//sub , zero
               Slt = 3'b111;//slt (set less than)
   
alu alu_t(A,B,ALUop,Overflow,CarryOut,Zero,Result);
   initial
    fork
    clk=1;
    A=0;
    B=0;
    filew=$fopen("file01.txt");
    OrderNumber=0;
    //store order
    order[0]= And;//and
    ///////////////////////////
	order[1]= Sltu;
	order[2]= Sll;
	order[3]= Lu;
	///////////////////////////
    order[4]= Or;//or
    order[5]= Add;//add
    order[6]= Sub;//sub , zero
    order[7]= Slt;//slt (set less than)
	
	
    //stop
    #stoptime $stop;
    join
 
   //change input
   always #(0.5*c) clk=~clk;
   always #c A=A+1;
   always #(ShortDataWide*c) B=B+1;
   always #OneOrderTime OrderNumber=OrderNumber+1;
   assign ALUop=order[OrderNumber];
   
   //judge the output
   always@(negedge clk)
    begin
 ///   #0.2  //test output and avoid input change
    case(ALUop)
    
       And:
           begin
            if( Result === (A & B) )
               begin
               $display($time,"And:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"And:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               end//if
            else
               begin
               $display($time,"And:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"And:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               end//else                
           end//and

       Or:
           begin
           if( Result === (A | B) )
               begin
               $display($time,"Or :ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Or :ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               end//if
            else
               begin
               $display($time,"Or :ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Or :ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               end//else                
           end//or
            
       Add:
               begin
               if(    {CarryOut,Result}=== ( A + B )  //add right 
                   &&
                   //CarryOut
                   (  ( A+B>=MaxData ) && (CarryOut===1)
                   || ( A+B<=MaxData ) && (CarryOut===0)
                   )
                   &&
                   //overflow
                   (  (A[wide-1]!==B[wide-1]) && Overflow===0 //+add-,no overflow
                   || (A[wide-1]===B[wide-1]) && (A[wide-1]===AddResult[wide-1]) && Overflow===0 //no overflow
                   || (A[wide-1]===B[wide-1]) && (A[wide-1]!==AddResult[wide-1]) && Overflow===1 //overflow
                   )
                &&//zero
                       (   ( (Result===0) && (Zero===1) )|| ( (Result!==0) && (Zero===0) )
                        )                   
               )
                   begin
                   $display($time,"Add :ALUop=%b, A=%b, B=%b, Result=%b, A+B=%b, CarryOut=%b, Overflow=%b, Zero=%b, right\n",ALUop,A,B,Result,A+B,CarryOut,Overflow,Zero);
                   $fdisplay(filew,$time,"Add :ALUop=%b, A=%b, B=%b, Result=%b, A+B=%b, CarryOut=%b, Overflow=%b, Zero=%b, right\n",ALUop,A,B,Result,A+B,CarryOut,Overflow,Zero);
                   end//if
                else
                   begin
                   $display($time,"Add :ALUop=%b, A=%b, B=%b, Result=%b, A+B=%b, CarryOut=%b, Overflow=%b, Zero=%b, error*****************\n",ALUop,A,B,Result,A+B,CarryOut,Overflow,Zero);
                   $fdisplay(filew,$time,"Add :ALUop=%b, A=%b, B=%b, Result=%b, A+B=%b, CarryOut=%b, Overflow=%b, Zero=%b, error*****************\n",ALUop,A,B,Result,A+B,CarryOut,Overflow,Zero);
                   end//else
               end//add
       
       Sub:       
               begin
               if(   Result=== (A - B)   //add right 
                   &&//overflow
                    ( (A[wide-1]===B[wide-1]) && Overflow===0 //,no overflow
                   || (A[wide-1]!==B[wide-1]) && (A[wide-1]===SubResult[wide-1]) && Overflow===0 //no overflow
                   || (A[wide-1]!==B[wide-1]) && (A[wide-1]!==SubResult[wide-1]) && Overflow===1 //overflow
                   )
                   &&//zero
                   (   ( (Result===0) && (Zero===1) )|| ( (Result!==0) && (Zero===0) )
                    )
                   &&( ( $unsigned(A)<$unsigned(B) )&& (CarryOut===1)|| ( $unsigned(A) >= $unsigned(B) ) && ( CarryOut===0) )            
                 )//if
                   begin
                   $display($time,"Sub :ALUop=%b, A=%b, B=%b, Result=%b, A-B=%b, CarryOut=%b, Overflow=%b, Zero=%b, right\n",ALUop,A,B,Result,A-B,CarryOut,Overflow,Zero);
                   $fdisplay(filew,$time,"Sub :ALUop=%b, A=%b, B=%b, Result=%b, A-B=%b, CarryOut=%b, Overflow=%b, Zero=%b, right\n",ALUop,A,B,Result,A-B,CarryOut,Overflow,Zero);
                   end//if
                else
                   begin
                   $display($time,"Sub :ALUop=%b, A=%b, B=%b, Result=%b, A-B=%b, CarryOut=%b, Overflow=%b, Zero=%b, error*****************\n",ALUop,A,B,Result,A-B,CarryOut,Overflow,Zero);
                   $fdisplay(filew,$time,"Sub :ALUop=%b, A=%b, B=%b, Result=%b, A-B=%b, CarryOut=%b, Overflow=%b, Zero=%b, error*****************\n",ALUop,A,B,Result,A-B,CarryOut,Overflow,Zero);
                   end//else
               end//sub
      Slt:
           begin
            if( ( $signed(A) < $signed(B) ) && (Result===1) || ( $signed(A) >= $signed(B) ) && (Result===0) )
               begin
               $display($time,"Slt:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Slt:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               end//if
            else
               begin
               $display($time,"Slt:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Slt:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               end//else                
           end//slt
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	Sltu:
			begin
			if( ( $unsigned(A) < $unsigned(B) ) && (Result===1) || ( $unsigned(A) >= $unsigned(B) ) && (Result===0) )
               begin
               $display($time,"Sltu:ALUop=%b, A=%b, B=%b, Result=%b, CarryOut=%b, rignt\n",ALUop,A,B,Result,CarryOut);
               $fdisplay(filew,$time,"Sltu:ALUop=%b, A=%b, B=%b, Result=%b, CarryOut=%b, rignt\n",ALUop,A,B,Result,CarryOut);
               end//if
            else
               begin
               $display($time,"Sltu:ALUop=%b, A=%b, B=%b, Result=%b, CarryOut=%b, error*****************\n",ALUop,A,B,Result,CarryOut);
               $fdisplay(filew,$time,"Sltu:ALUop=%b, A=%b, B=%b, Result=%b, CarryOut=%b, error*****************\n",ALUop,A,B,Result,CarryOut);
               end//else                
			end//Sltu
	
	 Sll:
           begin
            if( Result === ( B << A ) )
               begin
               $display($time,"Sll:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Sll:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               end//if
            else
               begin
               $display($time,"Sll:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Sll:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               end//else                
           end//Sll
		   
	 Lu:
           begin
            if( Result === ( B << (wide/2) ) )
               begin
               $display($time,"Lu:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Lu:ALUop=%b, A=%b, B=%b, Result=%b, rignt\n",ALUop,A,B,Result);
               end//if
            else
               begin
               $display($time,"Lu:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               $fdisplay(filew,$time,"Lu:ALUop=%b, A=%b, B=%b, Result=%b, error*****************\n",ALUop,A,B,Result);
               end//else                
           end//Lu
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			   
       endcase
    end//always


endmodule
