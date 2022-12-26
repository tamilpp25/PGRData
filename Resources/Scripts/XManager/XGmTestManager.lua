XGmTestManager = XGmTestManager or {}
local Panel

local function CheckLogin()
    if not XLoginManager.IsLogin() then
        XUiManager.TipError("请先登录")
        return false
    end

    return true
end

local function Open(name, ...)
    if not CheckLogin() then
        return
    end

    XLuaUiManager.Open(name, ...)
end

local function OpenActivity()
    XActivityBriefConfigs.TestOpenActivity()
    XUiManager.SystemDialogTip("", "开启活动成功，重新登录生效", XUiManager.DialogType.OnlySure, nil, function()
        XLoginManager.DoDisconnect()
    end)
end

-----------更新版本信息------------
local TxtVersion
local function UpdateVersionInfo()
    if not TxtVersion then return end
    if CS.XInfo.Version == CS.XRemoteConfig.ApplicationVersion then
        TxtVersion.text = string.format("客户端版本\n<color=#FFE900>%s</color>", CS.XRemoteConfig.ApplicationVersion)
    else
        TxtVersion.text = string.format("原版本%s\n<color=#FFE900>现版本%s</color>", CS.XInfo.Version, CS.XRemoteConfig.ApplicationVersion)
    end
end
---------------------------------

local function AddMoeWar()
    Panel:AddButton("萌战主页", function()
        Open("UiMoeWarMain")
    end)

    Panel:AddButton("萌战信息界面", function()
        Open("UiMoeWarMessage")
    end)

    Panel:AddButton("萌战排行榜", function()
        Open("UiMoeWarRankingList")
    end)

    Panel:AddButton("萌战赛程", function()
        Open("UiMoeWarSchedule")
    end)

    local playerId = 1
    local itemCount = 1
    local itemNo = 1

    Panel:AddInput("投票Id", function(value)
        playerId = tonumber(value)
    end)

    Panel:AddInput("道具数量", function(value)
        itemCount = tonumber(value)
    end)

    Panel:AddInput("道具类型", function(value)
        itemNo = tonumber(value)
    end)

    Panel:AddButton("萌战投票", function()
        XDataCenter.MoeWarManager.GetPlayer(playerId):RequestVote(itemNo, itemCount)
    end)

    ---------萌战动画 begin------------
    local winnerIndex = 1
    local animGroupIds = {}

    Panel:AddInput("胜利跑道\nIndex(1/2/3)", function(value)
        winnerIndex = tonumber(value)
    end)

    for index = 1, 3 do
        Panel:AddInput("动画组Id" .. index, function(value)
            animGroupIds[index] = tonumber(value)
        end)
    end

    Panel:AddButton("萌战动画", function()
        XMoeWarConfig.ReloadAnimationConfigs()
        XLuaUiManager.Open("UiMoeWarAnimation", animGroupIds, winnerIndex)
    end)
    ---------萌战动画 end------------
end

local function AddSvnFunction()
    local tool = CS.XExternalTool
    local runSvn = tool.RunSvn
    local asynRunTool = asynTask(tool.RunToolInNewThread)
    local svnGuiTool = "TortoiseProc.exe"
    local svnTool = tool.SvnPath

    local upCmd = "update --non-interactive "
    local checkRevCmd = "info --show-item last-changed-revision "
    local log = XUiManager.TipMsgEnqueue
    local manualResolveTip = function()
        log("如果弹窗有红色列表，请手动解决冲突。如无则请手动关闭")
    end

    Panel:AddButton("更新资源包", function()
        RunAsyn(function()
            log("开始更新打包机已打包资源")
            local oldRev = runSvn(checkRevCmd..tool.ProductPath.."File");
            asynRunTool(svnTool, "cleanup "..tool.ProductPath.."File", false)
            asynRunTool(svnTool, upCmd..tool.ProductPath.."File", false)

            local newRev = runSvn(checkRevCmd..tool.ProductPath.."File");
            if oldRev ~= newRev then
                manualResolveTip()
                asynRunTool(svnGuiTool,"/command:resolve /path:"..tool.ProductPath.."File", true)

                XLuaUiManager.RunMain()
                log("资源有更新，已自动重载并返回主界面")
            else
                log("资源无更新，版本号："..tonumber(newRev))
            end

            local info = runSvn("log -l 1 --incremental "..tool.ProductPath.."File");
            XUiManager.UiFubenDialogTip("打包机最近打包时间", info)
        end )
    end )

    Panel:AddButton("更新Lua", function()
        local oldRev = runSvn(checkRevCmd..tool.ProductPath.."Lua");
        runSvn("update --accept mf "..tool.ProductPath.."Lua")
        local newRev = runSvn(checkRevCmd..tool.ProductPath.."Lua");
        if oldRev ~= newRev then
            CS.XDebugManager.ReLogin()
            log("Lua有更新，已自动热重载并重登")
        else
            log("Lua无更新，版本号："..tonumber(newRev))
        end
    end )

    Panel:AddButton("更新配置表", function()
        RunAsyn(function()
            log("开始更新配置表")
            local oldRev = runSvn(checkRevCmd..tool.ProductPath.."Table");
            asynRunTool(svnTool, "cleanup "..tool.ProductPath.."Table", false)
            asynRunTool(svnTool, upCmd..tool.ProductPath.."Table", false)

            local newRev = runSvn(checkRevCmd..tool.ProductPath.."Table");
            if oldRev ~= newRev then
                manualResolveTip()
                asynRunTool(svnGuiTool,"/command:resolve /path:"..tool.ProductPath.."Table", true)

                CS.XDebugManager.ReloadLuaTable()
                local info = runSvn("log -l 15 --incremental "..tool.ProductPath.."Table");

                XUiManager.UiFubenDialogTip("更新记录", info)
                log("配置表有更新，已自动热重载并重登，请查看近期更新记录")
            else
                log("配置表无更新，版本号："..tonumber(newRev))
            end
        end )
    end )
end

local function AddArchiveFunction()
    Panel:AddSubMenu("SVN操作\n(beta)", AddSvnFunction)
    Panel:AddSubMenu("萌战相关", AddMoeWar)
    Panel:AddButton("开启活动", function()
        OpenActivity()
    end)

    Panel:AddButton("模拟Android", function()
        XUserManager.Platform = XUserManager.PLATFORM.Android
    end)

    Panel:AddButton("模拟iOS", function()
        XUserManager.Platform = XUserManager.PLATFORM.IOS
    end)

    Panel:AddButton("简单分享文字2", function()
        CS.XHeroShareAgent.Share(
        function(a)
            XLog.Debug("share status is ")
            XLog.Debug(a)
        end,
        isShowUi,
        CS.ShareType.Text,
        heroSharePlatform,
        " ",
        false,
        nil,
        nil,
        nil,
        "简单分享文字",
        nil
        )
    end)

    Panel:AddButton("分享文字", function()
        XPlatformShareManager.ShareByPlatformShareId(platformType, function(a) XLog.Debug("share status is ", a) end, 1, isShowUi)
    end)

    Panel:AddButton("分享链接", function()
        XPlatformShareManager.ShareByPlatformShareId(platformType, function(a) XLog.Debug("share status is ", a) end, 2, isShowUi)
    end)

    Panel:AddButton("分享图片", function()
        local runningPlatform = XUserManager.Platform
        local dirPath
        if runningPlatform == XUserManager.PLATFORM.Android then
            dirPath = CS.UnityEngine.Application.persistentDataPath .. "/../../../../DCIM/"
        elseif runningPlatform == XUserManager.PLATFORM.IOS then
            dirPath = CS.UnityEngine.Application.persistentDataPath .. "/"
        elseif runningPlatform == XUserManager.PLATFORM.Win then
            dirPath = CS.UnityEngine.Application.persistentDataPath .. "/"
        end
        if dirPath then
            local testPicName = "test.png"
            local fileFullPath = dirPath .. testPicName
            XLog.Debug("fileFullPath = ", fileFullPath)
            XPlatformShareManager.Share(XPlatformShareConfigs.ShareType.Image, platformType, function(a)
                XLog.Debug("share status is ", a)
            end, fileFullPath, nil, nil, nil, isShowUi)
        else
            XLog.Debug("dirPath is nil")
        end
    end)

    Panel:AddButton("打印平台", function()
        XLog.Debug("AppPackageName = " .. CS.XAppPlatBridge.GetAppPackageName())
    end, 3)
end

local function AddInfo()
    Panel:AddText("当前服务器", function(TxtServer)
        TxtServer.text = string.format("当前服务器\n<color=#F90000FF>%s</color>", XServerManager.GetCurServerName())
    end)
    TxtVersion = Panel:AddText("当前版本", UpdateVersionInfo)
    Panel:AddText("已启动时间", function(TxtTime)
        TxtTime.text = string.format("已启动时间\n<color=#6BFF00>%s</color>", XUiHelper.GetTime(math.floor(CS.UnityEngine.Time.realtimeSinceStartup) ,XUiHelper.TimeFormatType.DAILY_TASK))
    end)
    Panel:AddText("用户名", function(TxtUsername)
        TxtUsername.text = string.format("用户名\n<color=#48E0F0>%s</color>", XUserManager.UserName or "未登录")
    end)
end

local function AddServerFunction()
    local version = 0
    Panel:AddInput("版本号数字", function(value)
        version = tonumber(value) or 0
    end)
    Panel:AddButton("改版本号", function()
        local newVersion = string.format("1.%d.0", version)
        CS.XRemoteConfig.SetVersion(newVersion)
        UpdateVersionInfo()
        if version == 0 then
            XUiManager.TipMsgEnqueue("版本号被改为"..newVersion.."主干。如需切换到分支，输入单个数字即可，例如输入20表示\"1.20分支\"")
        else
            XUiManager.TipMsgEnqueue("版本号被改为"..newVersion.."分支。如需切换到主干，输入0即可")
        end
    end)
    Panel:AddButton("重置版本号(远程配置)", function()
        XUiManager.TipMsg("正在重置远程配置")
        CS.XRemoteConfig.Reset()
        XScheduleManager.ScheduleOnce(function()
            XServerManager.Init()
            XUiManager.TipMsgEnqueue("版本号被改为"..CS.XRemoteConfig.ApplicationVersion)
            UpdateVersionInfo()
        end, 2200)
    end)

    local tool = CS.XExternalTool
    local serverPath = tool.ProductPath.."Bin/NewServer/Bin/"
    Panel:AddButton("开启/重启本地服",function()
        tool.RunToolInNewThread(serverPath.."Start.bat",nil, true)
    end)

    Panel:AddButton("关闭本地服",function()
        tool.RunToolInNewThread(serverPath.."Stop.bat",nil, true)
    end)

    Panel:AddButton("本地服清库",function()
        XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), "是否确定进行清库操作？\n操作后将无法恢复！", XUiManager.DialogType.Normal, nil, function()
            tool.RunToolInNewThread(serverPath.."ClearDb.bat",nil, true)
        end)
    end)
end

local function AddDebugUse()
    local uiName = "UiSet"
    Panel:AddInput("界面名称", function(value)
        uiName = value
    end)

    Panel:AddButton("打开界面", function()
        Open(uiName)
    end)

    Panel:AddButton("重载Ui配置表", function()
        CS.XUiManager.Instance:Reset()
        CS.XDebugManager.ReLogin()
    end)
    ---------新增临时服 begin------------
    local ip
    Panel:AddInput("临时服IP:", function(value)
        ip = tostring(value)
    end)

    Panel:AddButton("新增临时服", function()
        local result, desc = XServerManager.InsertTempServer(ip)
        if not result then
            XUiManager.TipMsg(desc)
        else
            XUiManager.TipMsg("成功")
        end
    end)
    ---------新增临时服 end------------

    local keyWord
    Panel:AddInput("协议关键字", function(value)
        keyWord = value
    end)

    Panel:AddButton("添加协议关键字", function()
        if string.IsNilOrEmpty(keyWord) then
            XUiManager.TipMsg("请输入网络协议关键字")
        else
            table.insert(XRpc.DebugKeyWords, keyWord)
            XUiManager.TipMsg("添加成功，实用功能中开启网络调试日志即可查看")
        end

    end)

    Panel:AddButton("清空协议关键字", function()
        XRpc.DebugKeyWords = {}
    end)

    Panel:AddButton("替换进战Loading界面", function()
        XDataCenter.FubenManager.OpenFightLoading = function()
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LOADINGFINISHED)
            local XArchiveCGEntity = require("XEntity/XArchive/XArchiveCGEntity")
            XLuaUiManager.Open("UiArchiveCGDetail", {XArchiveCGEntity.New(106013)}, 1)
        end

        XDataCenter.FubenManager.CloseFightLoading = function()
            XLuaUiManager.Remove("UiArchiveCGDetail")
        end

        XUiManager.TipMsg("进战界面替换成spine动画成功，重登后恢复")
    end)
end

local function AddTestUse()
    local guideId = 50102
    Panel:AddInput("引导Id", function(value)
        guideId = tonumber(value)
    end)

    Panel:AddButton("手动开启引导", function()
        XDataCenter.GuideManager:PlayGuide(guideId)
    end)

    Panel:AddButton("关闭新手引导", function()
        XDataCenter.GuideManager.ResetGuide()
    end)

    ---------UI遮罩测试 begin------------
    local maskTime = 0--遮罩计时
    local timeId = nil

    local txtMaskTime = Panel:AddText(string.format("距离上一次遮罩计时:<color=#F90000FF>%d</color>秒", maskTime))

    local updateTxt = function()
        if XTool.UObjIsNil(txtMaskTime) then return end
        txtMaskTime.text = string.format("距离上一次遮罩计时:<color=#F90000FF>%d</color>秒", maskTime)
    end

    local reset = function()
        maskTime = 0
        if timeId then
            XScheduleManager.UnSchedule(timeId)
            timeId = nil
        end
    end

    local addTimer = function()
        timeId = XScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(txt) then
                reset()
                return
            end
            maskTime = maskTime + 1
            updateTxt()
        end, XScheduleManager.SECOND)
    end

    Panel:AddButton("添加UI遮罩", function()
        reset()
        updateTxt()
        addTimer()
        XLuaUiManager.SetMask(true)
    end)

    Panel:AddButton("取消UI遮罩", function()
        updateTxt()
        XLuaUiManager.SetMask(false)
    end)
    ---------UI遮罩测试 end------------
    ---------LUA内存 begin------------
    Panel:AddButton("开始记录LUA内存", function()
        XLuaMemoryMonitor.StartRecordAlloc()
    end)

    Panel:AddButton("结束记录LUA内存", function()
        XLuaMemoryMonitor.StopRecordAlloc()
    end)
    ---------LUA内存 end------------
    ---------机器人配置调试 begin------------
    --[[    
    显示武器共鸣技能、意识共鸣技能、意识超频技能增加的生命/会心/防御/攻击数值
    显示成员当前的战斗力
    显示伙伴当前的战力、攻击力数值
    ]]
    local robotId = 0
    Panel:AddInput("机器人Id", function(value)
        robotId = tonumber(value)
    end)

    Panel:AddButton("查看机器人数据", function()
        if not XTool.IsNumberValid(robotId) then
            XUiManager.TipMsg("请先输入robotId!")
            return
        end

        if not XRobotManager.CheckRobotExist(robotId) then
            XUiManager.TipMsg("robotId不正确，找不到对应配置，robotId: " .. robotId .. ", 配置路径: " .. XRobotManager.GetConfigPath())
            return
        end

        local partner = XRobotManager.GetRobotPartner(robotId)
        local partnerAttr = not XTool.IsTableEmpty(partner) and partner:GetPartnerAttrMap(partner:GetLevel())
        local equipResonanceAttr = XRobotManager.GetRobotResonanceAbilityList(robotId)
        local equipAwakenAttr = XRobotManager.GetRobotAwakenAbilityList(robotId)

        local content = string.format(
        [[
                机器人战力: %d\n
                机器人伙伴战力: %d\n
                机器人伙伴攻击力: %d\n
                武器/意识共鸣增加属性值: %s\n
                意识超频增加属性值: %s\n
                ]]
        , XRobotManager.GetRobotAbility(robotId)
        , XRobotManager.GetRobotPartnerAbility(robotId)
        , not XTool.IsTableEmpty(partnerAttr) and partnerAttr[1].Value or 0
        , not XTool.IsTableEmpty(equipResonanceAttr) and "详见LOG" or "空"
        , not XTool.IsTableEmpty(equipAwakenAttr) and "详见LOG" or "空"
        )
        XUiManager.UiFubenDialogTip("机器人数据", content)
        if not XTool.IsTableEmpty(equipResonanceAttr) then
            XLog.Debug("机器人Id: " .. robotId .. ", 武器/意识共鸣增加属性值: ", equipResonanceAttr)
        end
        if not XTool.IsTableEmpty(equipAwakenAttr) then
            XLog.Debug("机器人Id: " .. robotId .. ", 意识超频增加属性值: ", equipAwakenAttr)
        end
    end)

    local XRobot = require("XEntity/XRobot/XRobot")
    XRobot.New(1001)
    ---------机器人配置调试 end------------
end


local function AddPlannerUse()
    local cueId
    local typeId
    Panel:AddInput("CueId", function(value)
        cueId = tonumber(value)
    end)
    Panel:AddInput("音频类型", function(value)
        typeId = tonumber(value)
    end)

    local btnPlay = Panel:AddButton("播放音效", function()
        if not cueId or not typeId then
            XUiManager.TipMsg("请填写CueId和音频类型（1->BGM、2->音效、3->CV）后使用，例如填写1020、2将播放进入战斗音效")
            return
        end
        CS.XAudioManager.StopAll()
        XSoundManager.PlayFunc[typeId](cueId)
    end)

    if btnPlay then
        btnPlay.transform:GetComponent("XUguiPlaySound").enabled = false
    end

    Panel:AddButton("关闭音效", function()
        CS.XAudioManager.StopAll()
    end)


    local skipId
    Panel:AddInput("Skip跳转Id", function(value)
        skipId = tonumber(value)
    end)

    Panel:AddButton("开始跳转", function()
        if skipId then
            XFunctionManager.SkipInterface(tonumber(skipId))
        else
            XUiManager.TipMsg("请输入正确的SkipId后操作")
        end
    end)
end

--------------Ui组件创建 begin----------------
function XGmTestManager.Init()
    Panel = CS.XDebugManager.DebuggerGm
    Panel:AddSubMenu("当前信息", AddInfo, true)
    Panel:AddSubMenu("服务器", AddServerFunction, true)
    Panel:AddSubMenu("开发专用", AddDebugUse)
    Panel:AddSubMenu("测试专用", AddTestUse)
    Panel:AddSubMenu("策划专用", AddPlannerUse)
    Panel:AddSubMenu("归档功能", AddArchiveFunction)
end
--------------Ui组件创建 end----------------