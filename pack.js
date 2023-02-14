// 引入第三方模块
const {NodeSSH} = require('node-ssh');
const compressing = require('compressing');
const ChatBot = require('dingtalk-robot-sender');

// 初始化变量
const projectName = process.env.CI_PROJECT_NAME; // 由环境变量获取的工程名称
const appDir = `/var/www/html`;       // 应用根位置
const host = process.env.HOST;
const sshPort = process.env.SSHPORT;    // 下载端口
const port = process.env.PORT;    // 下载端口
const username = process.env.USERNAME;
const password = process.env.PASSWORD;
const bashUrl = "https://oapi.dingtalk.com/robot/send?access_token=";
const dingToken = process.env.DINGTOKEN;

// 定义开始函数，在文件结尾调用
const start = async function () {
  try {
    console.log('尝试连接生产服务器');
    const ssh = new NodeSSH();
    await ssh.connect({
      host: `${host}`,
      port: `${sshPort}`,
      username: `${username}`,
      password: `${password}`
    });

    const d_t = new Date();

    let year = d_t.getFullYear();
    let month = ("0" + (d_t.getMonth() + 1)).slice(-2);
    let day = ("0" + d_t.getDate()).slice(-2);
    const zipName = year + month + day + "_" + projectName;

    await compressing.zip.compressDir('dist', `${zipName}.zip`)
        .then(() => {
          console.log('压缩成功');
        })
        .catch(err => {
          console.error(err);
        });

    console.log('开始上传压缩包');
    await ssh.putFile(`${zipName}.zip`,
        `${appDir}/${zipName}.zip`)
    await dingSendSuccess(zipName);

  } catch (e) {
    console.log('打包发生错误', e);
    await dingSendError(e.message);
  } finally {
    process.exit(0);
  }
}

const dingSendSuccess = async function (zipName) {
  try {
    const robot = new ChatBot({
      webhook: bashUrl + dingToken
    });
    console.log("46");
    let downloadUrl = host + ":" + port + "/" + zipName + ".zip";
    let title = "#### 😀 😃 😄 😁 😆";
    let text = "## 😀 😃 😄 😁 😆\n" +
        `> ### ${projectName} 打包成功!  [下载地址](http://${downloadUrl}) \n`;

    await robot.markdown(title, text, {}).then((res) => {
      console.log("响应信息:" + res.data);
    });

  } catch (e) {
    console.log('推送错误', e);
  } finally {
    process.exit(0);
  }

}

const dingSendError = async function (error) {
  try {
    const robot = new ChatBot({
      webhook: bashUrl + dingToken
    });
    let title = "#### 😢 👿 😧 💔";
    let text = "## 😢 👿 😧 💔\n" +
        `> ### ${projectName} 打包失败!  \n` +
        `> #### 错误信息: ${error}  \n`;

    await robot.markdown(title, text, {}).then((res) => {
      console.log("响应信息:" + res);
    });

  } catch (e) {
    console.log('推送错误', e);
  } finally {
    process.exit(0);
  }

}

start().then().catch(function (error) {
  console.log('发生错误', error);
  process.exit(1);
});
