local XLevelTools = {}
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

---标准初始化猎锚勾点方法
---@param anchorConfig table 配置的所有锚点
---@return table 初始化后，根据PlaceId排序后取得对象引用的配置数据
function XLevelTools.InitAnchor(anchorConfig)
    local anchors = {}
    for _, v in pairs(anchorConfig) do
        v.agent = XDlcScriptManager.GetSceneObjectScript(v.placeId)
        v.agent:InitState(v.type, v.defaultEnable)
        anchors[v.placeId] = v
    end
    return anchors
end

---标准初始化带锚点的升降塔方法
---@param towerConfig table 配置的所有塔
---@return table 初始化后，根据PlaceId排序后取得对象引用的配置数据
function XLevelTools.InitTower(towerConfig)
    local towers = {}
    for _, v in pairs(towerConfig) do
        v.agent = XDlcScriptManager.GetSceneObjectScript(v.placeId)
        v.agent:InitState(v)
        towers[v.placeId] = v
    end
    return towers
end

---标准初始化开关方法
---@param switchConfig table 配置的所有开关
---@return table 初始化后，根据PlaceId排序后取得对象引用的配置数据
function XLevelTools.InitSwitch(switchConfig)
    local switches = {}
    for _, v in pairs(switchConfig) do
        v.agent = XDlcScriptManager.GetSceneObjectScript(v.placeId)
        v.agent:SetTriggerHandler(v.object, v.func, v.param)
        v.agent:InitState(v.defaultEnable)
        v.agent:SetOptions(v.autoReboot, v.autoRebootCoolDown, v.triggerTimes)
        switches[v.placeId] = v
    end
    return switches
end

--{{{Timer 已弃用 ------------------------------------------------------------------------------------

---初始化计时器，返回一个计时器数据 已弃用
---@return table timer
function XLevelTools.NewTimer()
    return {
        tasks = {},
        incId = 0
    }
end

---设置延时参数 已弃用
---@param object table 执行方法的对象,当调用静态方法时此为第一个变量
---@param timer table 计时器数据
---@param delayTime number 延迟执行的时间
---@param func function 延迟执行的方法
---@param fucParam boolean|number 延迟执行的方法的参数,当调用静态方法时此为第二个变量
function XLevelTools.TimerSetDelayFunction(timer, object, delayTime, func, fucParam)
    local task = {}
    task.delayTime = delayTime
    task.countTime = 0
    task.func = func
    task.complete = false
    task.id = timer.incId + 1
    task.fucParam = fucParam
    task.object = object

    timer.incId = task.id
    timer.tasks[#timer.tasks + 1] = task
    XLog.Debug("注册延时事件" .. timer.incId .. "  param" .. tostring(task.fucParam) .. "成功")
    return task.id
end

---撤销任务 已弃用
function XLevelTools.TimerRemove(timer, id)
    for i = 1, #timer.tasks do
        local task = timer.tasks[i]
        if task.id == id then
            table.remove(timer.tasks, i)
            break
        end
    end
end

---清理 已弃用
function XLevelTools.TimerClear(timer)
    for i = 1, #timer.tasks do
        timer.tasks[i] = nil
    end
end

function XLevelTools.TimerUpdate(timer, dt)
    for _, task in pairs(timer.tasks) do
        task.countTime = task.countTime + dt
        if task.countTime >= task.delayTime then
            if task.func ~= nil then
                XLog.Debug("执行延时任务" .. tostring(task.id) .. "  param" .. tostring(task.fucParam))
                task.func(task.object, task.fucParam)
            end
            task.complete = true
        end
    end

    -- 清除已完成的任务（倒序遍历，避免迭代器错误
    for i = #timer.tasks, 1, -1 do
        local task = timer.tasks[i]
        if task.complete then
            table.remove(timer.tasks, i)
        end
    end
end
--}}}Timer ------------------------------------------------------------------------------------

--{{{Guider ------------------------------------------------------------------------------------

---初始化指引工具，需要传入关卡的引导配置
---@param guideConfig table 关卡配置中的引导配置数据，格式详见SceneObjectsProperly
---@return table 一份完整的引导实例化数据
function XLevelTools.NewGuider(guideConfig, object, localPlayer)
    local newGuideConfig = XTool.Clone(guideConfig)
    for i, v in pairs(newGuideConfig) do
        --[[                XLog.Debug("-----------------------")
                        XLog.Debug(i)
                        XLog.Debug("GuideId " .. tostring(v.GuideId))
                        XLog.Debug("ClickKey " .. tostring(v.ClickKey))
                        XLog.Debug("Next " .. tostring(v.Next))
                        XLog.Debug("CallBackObj " .. tostring(v.CallBackObj))
                        XLog.Debug("CallBackFuncName " .. tostring(v.CallBackFuncName))]]
        if v.CallBackFuncName ~= nil and v.CallBackObj == nil then
            v.CallBackObj = object
        end
    end
    ---@class XLevelGuider
    return {
        Config = newGuideConfig,
        index = nil,
        guideId = nil,
        keyListening = false, ---是否需要按键监听
        duration = nil, ---当前对话持续时间
        currentDuration = 0, ---已经经过时间
        pause = false,
        next = nil,
        conversationSet = nil,
        callBackObj = nil,
        callBackFuncName = nil,
        callBackParam = nil,
        localPlayer = localPlayer, --用来添加屏幕暗角
    }
end

---指引工具状态监听，处理手动配置的按键监听和持续时间
---@param guider XLevelGuider 引导实例化数据
---@param dt number @delta time
function XLevelTools.UpdateGuide(guider, dt)
    if guider.guideId ~= nil then
        guider.currentDuration = guider.currentDuration + dt
        if guider.Duration ~= nil then
            if guider.CurrentDuration >= guider.Duration then
                ---播放下一个或者关闭
                XLog.Debug("<color=#804000>[Guider]</color>时间到了 " .. tostring(guider.index))
                XLevelTools.NextGuide(guider)
            end
        end
        if guider.keyListening --[[and guider.currentDuration >= 0.2]] then
            if FuncSet.IsKeyDown(guider.keyListening) then
                ---播放下一个或者关闭
                XLog.Debug("<color=#804000>[Guider]</color>监听到按键 " .. tostring(guider.index) .. " ;key " .. tostring(guider.keyListening))
                XLevelTools.NextGuide(guider)
            end
        end
    end
end

---显示引导
---@param guider XLevelGuider 引导实例化数据
---@param guideIndex number 需要播放的引导在关卡配置的数据中的索引
function XLevelTools.ShowGuide(guider, guideIndex)
    guider.index = guideIndex
    local guide = guider.Config[guideIndex]
    guider.guideId = guide.GuideId

    if guider.KeyListening == nil then
        FuncSet.HideGuide()
    end
    guider.keyListening = guide.ClickKey

    guider.duration = guide.duration
    guider.currentDuration = 0
    guider.next = guide.Next
    guider.callBackObj = guide.CallBackObj
    guider.callBackFuncName = guide.CallBackFuncName
    guider.callBackParam = guide.CallBackParam
    if guider.guideId ~= nil then

        FuncSet.ShowGuide(guider.guideId)
        if guider.conversationSet ~= guide.ConversationSet then
            --需要变更对话
            if guider.conversationSet == "Air" and guide.ConversationSet == nil then
                XLevelTools.SetupConversationUi("AirFight", guider.localPlayer)
            else
                XLevelTools.SetupConversationUi(guide.ConversationSet, guider.localPlayer)
            end
            guider.conversationSet = guide.ConversationSet
        end

        if guide.Pause == true and not guider.pause then
            --开启暂停
            XLevelTools.PauseAllNpc(true)
        elseif guider.pause and not (guide.Pause == true) then
            --关闭暂停
            XLevelTools.PauseAllNpc(false)
        end
        guider.pause = guide.Pause == true
    end
end

---自动播放引导方法
---@param guider XLevelGuider 引导实例化数据
function XLevelTools.NextGuide(guider)
    local callBack = false
    local callBackObj
    local callBackFuncName
    local callBackParam
    if guider.callBackObj ~= nil and guider.callBackFuncName ~= nil then
        callBack = true
        callBackObj = guider.callBackObj
        callBackFuncName = guider.callBackFuncName
        callBackParam = guider.callBackParam
    end

    if guider.next ~= nil then
        XLog.Debug("<color=#804000>[Guider]</color>播放一个 " .. tostring(guider.next))
        XLevelTools.ShowGuide(guider, guider.next)
    else
        guider.guideId = nil
        guider.index = nil

        XLog.Debug("<color=#804000>[Guider]</color>自动关闭对话")
        FuncSet.HideGuide()
        guider.KeyListening = nil

        if guider.conversationSet ~= nil then
            if guider.conversationSet == "Air" or guider.conversationSet == "AirFight" then
                XLevelTools.SetupConversationUi("AirFight", guider.localPlayer)
            else
                XLevelTools.SetupConversationUi(nil, guider.localPlayer)
            end
            guider.conversationSet = nil
        end

        if guider.pause then
            XLevelTools.PauseAllNpc(false)
            guider.pause = false
        end
    end

    if callBack then
        XLog.Debug("<color=#804000>[Guider]</color>执行Guide回调" .. callBackFuncName .. " 参数:" .. tostring(callBackParam))
        callBackObj[callBackFuncName](callBackObj, callBackParam)
    end

end
---无视下一步，直接关闭guide，可以触发回调。TODO 优化GUIDE整个模块的写法
---@param guider XLevelGuider 引导实例化数据
function XLevelTools.CloseGuide(guider)

    guider.guideId = nil
    guider.index = nil
    XLog.Debug("<color=#804000>[Guider]</color>手动关闭对话")
    FuncSet.HideGuide()
    guider.KeyListening = nil
    if guider.conversationSet ~= nil then
        if guider.conversationSet == "Air" or guider.conversationSet == "AirFight" then
            XLevelTools.SetupConversationUi("AirFight", guider.localPlayer)
        else
            XLevelTools.SetupConversationUi(nil, guider.localPlayer)
        end
        guider.conversationSet = nil
    end

    if guider.pause then
        XLevelTools.PauseAllNpc(false)
        guider.pause = false
    end

    if guider.callBackObj ~= nil and guider.callBackFuncName ~= nil then
        guider.callBackObj[guider.callBackFuncName](guider.callBackObj, guider.callBackParam)
    end

end

---对话预设开关
function XLevelTools.SetupConversationUi(setName, npc)
    --XLog.Debug("<color=#804000>[Guider]</color>" .. tostring(setName))
    if setName == nil then
        XLevelTools.ConversationUIControl(false)
        XLevelTools.BasicFightUIControl(true)
        XLog.Debug("<color=#804000>[Guider]</color>关闭对话设置")
    elseif setName == "Normal" then
        XLevelTools.ConversationUIControl(true)
        XLevelTools.BasicFightUIControl(false)
        XLog.Debug("<color=#804000>[Guider]</color>普通对话设置")
    elseif setName == "Air" then
        XLevelTools.ConversationUIControl(true)
        XLevelTools.AirFightUIControl(false)
        XLog.Debug("<color=#804000>[Guider]</color>空中对话设置")
    elseif setName == "AirFight" then
        XLevelTools.ConversationUIControl(false)
        XLevelTools.AirFightUIControl(true)
        XLog.Debug("<color=#804000>[Guider]</color>空中战斗设置")
    end

    if npc ~= nil and FuncSet.CheckNpc(npc) then
        if setName == "Normal" or setName == "AirFight" then
            FuncSet.ApplyMagic(npc, npc, 5000004, 1)
        else
            FuncSet.ApplyMagic(npc, npc, 5000005, 1)
        end
    end

end

function XLevelTools.ConversationUIControl(enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Guide, EUiFightGuideWidgetKey.BtnNext, enable)

    --XLog.Debug("<color=#804000>[Guider]</color>对话UI控制")
end

function XLevelTools.BasicFightUIControl(enable)
    --FuncSet.SetUiActive(EUiIndex.EnergyBarPanel,  enable)
    --FuncSet.SetUiActive(EUiIndex.ManualLockPanel,  enable)
    --FuncSet.SetUiActive(EUiIndex.Reborn,  enable)
    FuncSet.SetUiActive(EUiIndex.SkillBallPanel, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.Joystick, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnDodge, enable)
    --FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnExSkill,  enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, enable)
    --XLog.Debug("<color=#804000>[Guider]</color>常规战斗UI控制" .. tostring(enable))
end

function XLevelTools.AirFightUIControl(enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    FuncSet.SetUiActive(EUiIndex.SkillBallPanel, enable)
    FuncSet.SetUiActive(EUiIndex.SpearPenetratePanel, enable)
end



--}}}Guider ------------------------------------------------------------------------------------

---全局静止开关
function XLevelTools.PauseAllNpc(enable)
    local npcList = FuncSet.GetNpcList()
    if enable then
        for _, npc in pairs(npcList) do
            FuncSet.AddBuff(npc, 5000002)
        end
        XLog.Debug("XTOOL: THE WORLD!!!")
    else
        for _, npc in pairs(npcList) do
            FuncSet.RemoveBuff(npc, 5000002)
        end
        XLog.Debug("XTOOL: DLROW EHT!!!")
    end
end
---开关战斗UI
function XLevelTools.SetFightUiActive(enable)
    FuncSet.SetUiActive(EUiIndex.SkillBallPanel, enable)
    ---FuncSet.SetUiActive(EUiIndex.SpearPointPanel, not enable)
    --FuncSet.SetUiActive(EUiIndex.EnergyBarPanel, not enable)
    ---FuncSet.SetUiActive(EUiIndex.ManualLockPanel, not enable)
    ---FuncSet.SetUiActive(EUiIndex.Reborn, not enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.Joystick, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnAttack, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnDodge, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnExSkill, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnJump, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnSpear, enable)
    FuncSet.SetUiWidgetActive(EUiIndex.Fight, EUiFightWidgetKey.BtnFocus, enable)
    XLog.Debug("<color=#804000>[Guider]</color>设置战斗UI开关" .. tostring(enable))
end

return XLevelTools