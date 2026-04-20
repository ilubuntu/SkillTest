import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

// 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
export function createFile(context: common.UIAbilityContext, filename: string): void {
  try {
    let cacheDir = context.cacheDir;
    // 新建并打开文件
    let file = fileIo.openSync(cacheDir + filename, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    // 写入一段内容至文件
    let writeLen = fileIo.writeSync(file.fd, "Try to write str.");
    console.info("The length of str is: " + writeLen);
    // 从文件读取一段内容
    let arrayBuffer = new ArrayBuffer(1024);
    class Option {
      public offset: number = 0;
      public length: number = 0;
    }
    let option = new Option();
    option.length = arrayBuffer.byteLength;
    let readLen = fileIo.readSync(file.fd, arrayBuffer, option);
    let buf = buffer.from(arrayBuffer, 0, readLen);
    console.info("the content of file: " + buf.toString());
    // 关闭文件
    fileIo.closeSync(file);
  } catch (e) {
    console.log("failed to create file", e)
  }
}

// 读取文件内容并写入到另一个文件
export function readWriteFile(context: common.UIAbilityContext, sourceFileName: string, targetFileName: string): void {
  try {
    let filesDir = context.cacheDir;
    // 打开文件
    let srcFile = fileIo.openSync(filesDir + sourceFileName, fileIo.OpenMode.READ_WRITE);
    let destFile = fileIo.openSync(filesDir + targetFileName, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    // 读取源文件内容并写入至目的文件
    let bufSize = 4096;
    let readSize = 0;
    let buf = new ArrayBuffer(bufSize);
    class Option {
      public offset: number = 0;
      public length: number = bufSize;
    }
    let option = new Option();
    option.offset = readSize;
    let readLen = fileIo.readSync(srcFile.fd, buf, option);
    while (readLen > 0) {
      readSize += readLen;
      fileIo.writeSync(destFile.fd, buf);
      option.offset = readSize;
      readLen = fileIo.readSync(srcFile.fd, buf, option);
    }
    // 关闭文件
    fileIo.closeSync(srcFile);
    fileIo.closeSync(destFile);
  } catch (e) {
    console.log("failed to read&write File file", e)
  }
}


// 查看文件列表
export function getListFile(context: common.UIAbilityContext): void {
  try {
    let filesDir = context.filesDir;
    let files = fileIo.listFileSync(filesDir);
    for (let i = 0; i < files.length; i++) {
      console.info(`The name of file: ${files[i]}`);
    }
  } catch (e) {
    console.log("failed to getListFile File file", e)
  }
}