conversation// 执行用例  y由云测下发任务
http://127.0.0.1:8000/api/cloud-api/baseline
Post 
 {
    "executionId":10,
    "testCase":{
	"input":"22",
	"expectedOutput":"",
	"fileUrl":""
}}

`fileUrl` 可为空；为空时不下载原始工程，workspace 初始内容为空。


// 更新执行状态
Post https://xxxxx/api/test-executions/{id}/report
{
      status: ExecutionStatus;
      errorMessage?: string;
      conversation?: Record<string, any>[];//和大模型的交互流程，暂时忽略
      executionLog：{}// 日志详细，云测只保存一份，每次传全量
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
	     codeQualityScore: number; // 当前固定为 0
	     expectedOutputScore: number; // 当前固定为 0
	     outputCodeUrl: string;
     diffFileUrl: string;
  }
}
