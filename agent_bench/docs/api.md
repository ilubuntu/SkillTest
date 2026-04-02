conversation// 执行用例  y由云测下发任务
Post 
{
   "executionId":10,
   "testCase":{
	"input":"22",
	"expectedOutput":"12",
	"fileUrl":"22222"
}}


// 更新执行状态
Post https://xxxxx/api/test-executions/{id}/report
{
      status: ExecutionStatus;
      errorMessage?: string;
      conversation?: Record<string, any>[];//和大模型的交互流程
}

export enum ExecutionStatus {PENDING = 'pending',RUNNING = 'running',COMPLETED = 'completed',FAILED = 'failed'}


//更新用例结果
Post https://xxxxx/api/execution-results
{
   testExecutionId: number；
   data：{
     isBuildSuccess: boolean;
     executionTime: number;
     tokenConsumption: number;
     iterationCount: number;
     codeQualityScore: number;
     expectedOutputScore: number;
     outputCodeUrl: string;
  }
}
