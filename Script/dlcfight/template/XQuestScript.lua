local base = require("Common/XQuestBase")
---@class XQuestScriptXXX
local XQuestScriptXXX = XDlcScriptManager.RegQuestStepScript(0000, "XQuestScriptXXX", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScriptXXX:Ctor(proxy)
    --self.Super.Ctor(self, proxy) --class机制会自动先执行基类构造函数，不需要手动调用
end

function XQuestScriptXXX:Init()
    --任务初始化
    --事件监听注册
    --容器初始化
end

function XQuestScriptXXX:Terminate()
    --任务结束
    --事件监听解除
    --容器清空
end

--===================[[ 任务步骤]]
--region ========================[[ 步骤1 ]]=============================>>
---@param self XQuestScriptXXX
XQuestScriptXXX.StepEnterFuncs[1] = function(self)
    --步骤的初始化，例如：
    --刷怪，生成动态对象等
end

---@param self XQuestScriptXXX
XQuestScriptXXX.StepHandleEventFuncs[1] = function(self, eventType, eventArgs)
    --步骤1的事件响应，例如：
    --怪物击杀，进入某区域等事件的响应
end

---@param self XQuestScriptXXX
XQuestScriptXXX.StepExitFuncs[1] = function(self)
    --步骤的结束处理，例如：
    --移除任务时创建的临时对象
    --如果特殊完成逻辑的定制
end
--endregion ========================[[ 步骤1 ]]=============================<<

--========================[[ 步骤2]]=============================<<

--复制步骤1的三个函数进行修改即可

--==============================================================>>