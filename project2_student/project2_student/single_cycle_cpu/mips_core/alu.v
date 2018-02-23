`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement a 4-bit ALU
    `define DATA_WIDTH 4
`else
    `define DATA_WIDTH 32
`endif

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [2:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);

	// TODO: insert your code
	
//	 successful design
        wire CarryOutHigh;// CarryOut of the highest effective bit (the bit before sign bit)
        reg [`DATA_WIDTH - 1:0] NegCodeB;//the Bu(3)Ma(3)of B
        wire [`DATA_WIDTH - 1:0] Less;        
        
        //all the result of different operation
        //in each ALUop case, select one Result from these results 
        wire[`DATA_WIDTH - 1:0] ResultAnd;
        wire[`DATA_WIDTH - 1:0] ResultOr;
        wire[`DATA_WIDTH - 1:0] ResultAddSub;//for add & sub case(the B is different)
        wire[`DATA_WIDTH - 1:0] ResultSlt;
        
 //       wire[`DATA_WIDTH - 2:0] ResultAddSubH; 
//        wire                    ResultAddSubS;
        wire CarryOutTemp; //in sub,CarryOut=~CarryOutTemp,in other case,CarryOut=CarryOutTemp
        
        //And
        assign ResultAnd = A & B;
        
        //Or
        assign ResultOr =  A | B;
        
        //And  Subtract      
        //in always, NegCodeB=B in Add case, NegCodeB=~B+1 in Sub case and Slt case
        assign { CarryOutHigh , ResultAddSub[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
        assign { CarryOutTemp , ResultAddSub[`DATA_WIDTH-1]   } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHigh ;
        
        //********** CarryOut ************
         //CarryOut is define for unsgined ,no define for signed
        assign CarryOut=(ALUop===3'b110 && B!==0 )?(~CarryOutTemp):CarryOutTemp;
        
         //********** Overflow ************
        //when the sign bit of A,B is the same,we should judge overflow       
        assign Overflow = (  ~( A[`DATA_WIDTH-1] ^ NegCodeB[`DATA_WIDTH-1] ) & ( CarryOutTemp ^ CarryOutHigh ) ) ^( (ALUop===3'b110 || ALUop===3'b111) && (NegCodeB[`DATA_WIDTH-1]===1 && NegCodeB[`DATA_WIDTH-2:0]===0) );
        
 
 /////////////////////////////////////////////////////////////
 ///////  a filed CarryOut and OverFlow design
 /////////////////////////////////////////////////////////////     
 //       assign { CarryOutHigh , ResultAddSubH[`DATA_WIDTH - 2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
 //       assign { CarryOut ,     ResultAddSubS                    } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHigh ;
          //CarryOut is define for unsgined ,no define for signed    
 //       assign ResultAddSub = {ResultAddSubS,ResultAddSubH[`DATA_WIDTH - 2:0]};
        
 
        
        //Slt
        assign Less[`DATA_WIDTH-1:1] = 0;
        assign Less[0] = ResultAddSub[`DATA_WIDTH-1] ^ Overflow; //signal slt (consider overflow)
    /////////////////assign Less[0] = CarryOut; // unsignal slt
        assign ResultSlt = (Less===1)?1:0;
        
       
        //********** Zero ************
        assign Zero = (ResultAddSub===0)?1:0;
        
        //********** Result ************
        //1.select the input B for the add_mode ( ~B+1 in substract case; B in add and all other case)
        //2.secelt the result for each case
        always@(*)
            begin
            case(ALUop)
               3'b000: //and
                begin
                NegCodeB = B;//useless
                Result = ResultAnd;
                end//case000
               
               3'b001: //or
                begin
                NegCodeB = B;//useless
                Result = ResultOr;
                end//case001
                
               3'b010://add
                begin
                NegCodeB = B;
                Result = ResultAddSub;       
                end//case010
                
                3'b110://subtract
                 begin            
                 NegCodeB = ~B + 1;
                 Result = ResultAddSub; 
                 end //case110
                 
                 
                3'b111://set on less than (slt)
                  begin
                  NegCodeB = ~B + 1;
                  Result = ResultSlt; 
                  end//case111
                  
                 default://other undefine ALUop case
                   begin
                   NegCodeB = B;//useless
                   Result = ResultAnd;
                   end//case000                
                  
                  endcase
            end//always
             
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*	 failed design (3)
	reg CarryOutHighCase;// CarryOut of the highest effective bit (the bit before sign bit)
	reg [`DATA_WIDTH - 1:0] NegCodeB;//the Bu(3)Ma(3)of B
    reg [`DATA_WIDTH - 1:0] Less;
    //CarryOut,Overflow,Zero are define as wire and can`t be redefine
    //so define these three reg for case model,and assign them to CarryOut,Overflow,Zero
    reg CarryOutSignCase;
    reg OverflowCase;
    reg ZeroCase;
    
    //all the result of different operation
    wire[`DATA_WIDTH - 1:0] ResultAnd;
    wire[`DATA_WIDTH - 1:0] ResultOr;
    
    reg[`DATA_WIDTH - 1:0] ResultAddSub;
    reg[`DATA_WIDTH - 1:0] ResultSlt;
    //only used in slt,before we get final Result,use TempResultSlt to store the A-B result,then we TempResultSlt to get Less ,and use Less to get final Result
    //using Result to get Less(without TempResultSlt) will creat a self-feedback,and cause problem  
    
    //And
    assign ResultAnd = A & B;
    
    //Or
    assign ResultOr =  A | B;
    
    //And  Subtract
    //********** CarryOut , Overflow ************
    //in always, NegCodeB<=B in Add case, NegCodeB<=~B+1 in Sub case and Slt case
//    assign { CarryOutHigh , ResultAddSub[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
//    assign { CarryOut ,     ResultAddSub[`DATA_WIDTH-1]   } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHigh ;//CarryOut is define for unsgined ,no define for signed
//    assign Overflow =   ~( A[`DATA_WIDTH-1] ^ B[`DATA_WIDTH-1] ) & ( CarryOut ^ CarryOutHigh );//when the sign bit of A,B is the same,we should judge overflow
    assign Overflow=OverflowCase;
    assign CarryOut=CarryOutSignCase;
    assign Zero=ZeroCase;
    
    //Slt
 //   assign Less[`DATA_WIDTH-1:1] = 0;
 //   assign Less[0] = ResultAddSub[`DATA_WIDTH-1] ^ Overflow; //signal slt (consider overflow)
/////////////////assign Less[0] = CarryOut; // unsignal slt
 //   assign ResultSlt = (Less===1)?1:0;
    
   
    //********** Zero ************
//    assign Zero = (A===B)?1:0;
    
    //********** Result ************
    always@(*)
        begin
        case(ALUop)
           000://and
            begin
            NegCodeB = B;//useless
            Result = ResultAnd;
            end//case000
           
           001://or
            begin
            NegCodeB = B;//useless
            Result = ResultOr;
            end//case001
            
           010://add
            begin
            NegCodeB = B;
            { CarryOutHighCase , ResultAddSub[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
            { CarryOutSignCase , ResultAddSub[`DATA_WIDTH-1]   } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHighCase ;//CarryOut is define for unsgined ,no define for signed            
            OverflowCase =   ~( A[`DATA_WIDTH-1] ^ B[`DATA_WIDTH-1] ) & ( CarryOutSignCase ^ CarryOutHighCase );
            Result = ResultAddSub;       
            end//case010
            
            110://subtract
             begin            
             NegCodeB = ~B + 1;
             { CarryOutHighCase , ResultAddSub[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
             { CarryOutSignCase , ResultAddSub[`DATA_WIDTH-1]   } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHighCase ;//CarryOut is define for unsgined ,no define for signed            
             OverflowCase =   ~( A[`DATA_WIDTH-1] ^ B[`DATA_WIDTH-1] ) & ( CarryOutSignCase ^ CarryOutHighCase );
             ZeroCase = (A===B)?1:0;         
             Result = ResultAddSub; 
             end //case110
             
             
             111://set on less than (slt)
              begin
              NegCodeB = ~B + 1;
              { CarryOutHighCase , ResultAddSub[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
              { CarryOutSignCase , ResultAddSub[`DATA_WIDTH-1]   } = A[`DATA_WIDTH-1]   + NegCodeB[`DATA_WIDTH-1]  + CarryOutHighCase ;//CarryOut is define for unsgined ,no define for signed            
              OverflowCase =   ~( A[`DATA_WIDTH-1] ^ B[`DATA_WIDTH-1] ) & ( CarryOutSignCase ^ CarryOutHighCase );
              Less[0] = ResultAddSub[`DATA_WIDTH-1] ^ OverflowCase; //signal slt (consider overflow)
              ResultSlt = (Less===1)?1:0;
              Result = ResultSlt; 
              end//case111
              
             default:
               begin
               NegCodeB = B;//useless
               Result = ResultAnd;
               end//case000                
              
              endcase
        end//always
*/             
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// failed design    (1)        
 /*   
    always@(A or B or ALUop)
    begin
    case(ALUop)
       000://and
        begin
        Overflow = 0; //no define
        CarryOut = 0; //no define
        Zero=0;     //no define
        Result = A & B;

        end//case000
       
       001://or
        begin
        Overflow = 0; //no define
        CarryOut = 0; //no define
        Zero = 0;     //no define
        Result = A | B;

        end//case001
        
       010://add
        begin
        
        NegCodeB = B;
        { CarryOutHigh , Result[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
        { CarryOut , Result[`DATA_WIDTH-1] } = A[`DATA_WIDTH-1] + NegCodeB[`DATA_WIDTH-1] + CarryOutHigh ;//CarryOut is define for unsgined ,no define for signed
        
       
        //{ CarryOutHigh ,EffectiveResult } = A[`DATA_WIDTH-2:0] + B[`DATA_WIDTH-2:0];
        //{ CarryOut , Result} = A + B;//CarryOut is define for unsgined ,no define for signed
        
        
        //Overflow is define for sgined ,no define for unsigned
        Overflow = ~( A[`DATA_WIDTH-1] ^ NegCodeB[`DATA_WIDTH-1] ) & ( CarryOut ^ CarryOutHigh );//when the sign bit of A,B is the same,we should judge overflow
        Zero = 0;//no define 
        
        end//case010
        
        110://subtract
         begin
         NegCodeB = ~B +1 ;
         { CarryOutHigh , Result[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
         { CarryOut , Result[`DATA_WIDTH-1] } = A[`DATA_WIDTH-1] + NegCodeB[`DATA_WIDTH-1] + CarryOutHigh ;//CarryOut is define for unsgined ,no define for signed
         
         //{ CarryOutHigh ,EffectiveResult } = A[`DATA_WIDTH-2:0] + ~B[`DATA_WIDTH-2:0] +1;
         //{ CarryOut , Result} = A + ~B + 1;//CarryOut is define for unsgined ,no define for signed
         
         //Overflow is define for sgined ,no define for unsigned
         Overflow = ~( A[`DATA_WIDTH-1] ^ B[`DATA_WIDTH-1] ) & ( CarryOut ^ CarryOutHigh );//when the sign bit of A,B is the same,we should judge overflow
         if( A===B )
            Zero = 1;
         else
            Zero = 0;
            
         end //case110
         
         
         111://set on less than (slt)
          begin
          NegCodeB = ~B +1 ;
          { CarryOutHigh , Result[`DATA_WIDTH-2:0] } = A[`DATA_WIDTH-2:0] + NegCodeB[`DATA_WIDTH-2:0];
          { CarryOut , Result[`DATA_WIDTH-1] } = A[`DATA_WIDTH-1] + NegCodeB[`DATA_WIDTH-1] + CarryOutHigh ;//CarryOut is define for unsgined ,no define for signed
           
            
                  { CarryOutHigh ,EffectiveResult } = A[`DATA_WIDTH-2:0] + ~B[`DATA_WIDTH-2:0] +1;
                  { CarryOut , Result} = A + ~B + 1;//CarryOut is define for unsgined ,no define for signed
                  
          
  //Overflow is define for sgined ,no define for unsigned
          Overflow = 0;//no define
          if(Result === 0)
             Zero = 1;
          else
             Zero = 0;
          end
          
          end//case111
          
          deafult:
            ;
            
          endcase
         end//always
*/

endmodule
