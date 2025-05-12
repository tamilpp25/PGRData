XGmTestManager = XGmTestManager or {}
local Panel

local ReLogin = CS.XDebugManager.ReLogin
local function Open(name, ...)
    if not XLoginManager.IsLogin() then
        XUiManager.TipMsg("请先登录")
        return
    end

    XLuaUiManager.Open(name, ...)
end

local function OpenActivity()
    XActivityBriefConfigs.TestOpenActivity()
    XUiManager.SystemDialogTip(
        "",
        "开启活动成功，重新登录生效",
        XUiManager.DialogType.OnlySure,
        nil,
        function()
            XLoginManager.DoDisconnect()
        end
    )
end

-----------更新版本信息------------
local TxtVersion
local function UpdateVersionInfo()
    if not TxtVersion then
        return
    end
    if CS.XInfo.Version == CS.XRemoteConfig.ApplicationVersion then
        TxtVersion.text = string.format("客户端版本\n<color=#FFE900>%s</color>", CS.XRemoteConfig.ApplicationVersion)
    else
        TxtVersion.text =
            string.format("原版本%s\n<color=#FFE900>现版本%s</color>", CS.XInfo.Version, CS.XRemoteConfig.ApplicationVersion)
    end
end
---------------------------------

local function AddMoeWar()
    Panel:AddButton(
        "萌战主页",
        function()
            Open("UiMoeWarMain")
        end
    )

    Panel:AddButton(
        "萌战信息界面",
        function()
            Open("UiMoeWarMessage")
        end
    )

    Panel:AddButton(
        "萌战排行榜",
        function()
            Open("UiMoeWarRankingList")
        end
    )

    Panel:AddButton(
        "萌战赛程",
        function()
            Open("UiMoeWarSchedule")
        end
    )

    local playerId = 1
    local itemCount = 1
    local itemNo = 1

    Panel:AddInput(
        "投票Id",
        function(value)
            playerId = tonumber(value)
        end
    )

    Panel:AddInput(
        "道具数量",
        function(value)
            itemCount = tonumber(value)
        end
    )

    Panel:AddInput(
        "道具类型",
        function(value)
            itemNo = tonumber(value)
        end
    )

    Panel:AddButton(
        "萌战投票",
        function()
            --XDataCenter.MoeWarManager.GetPlayer(playerId):RequestVote(itemNo, itemCount)
        end
    )

    ---------萌战动画 begin------------
    local winnerIndex = 1
    local animGroupIds = {}

    Panel:AddInput(
        "胜利跑道\nIndex(1/2/3)",
        function(value)
            winnerIndex = tonumber(value)
        end
    )

    for index = 1, 3 do
        Panel:AddInput(
            "动画组Id" .. index,
            function(value)
                animGroupIds[index] = tonumber(value)
            end
        )
    end

    Panel:AddButton(
        "萌战动画",
        function()
            XMoeWarConfig.ReloadAnimationConfigs()
            XLuaUiManager.Open("UiMoeWarAnimation", animGroupIds, winnerIndex, nil, {})
        end
    )

    Panel:AddButton(
        "萌战全动画",
        function()
            XMoeWarConfig.ReloadAnimationConfigs()
            local allAnimGroupIds = XMoeWarConfig.GetAllAnimationGroupIds()
            XLuaUiManager.Open("UiMoeWarAnimation", allAnimGroupIds, winnerIndex, nil, {})
        end
    )
    
    local roleIndex
    local animName
    Panel:AddInput(
        "动画名",
        function(value)
            animName = value
        end
    )

    Panel:AddInput(
        "角色Id",
        function(value)
            roleIndex = value
        end
    )
    
    Panel:AddButton(
        "播放动画",
        function()
            if not XLuaUiManager.IsUiShow("UiMoeWarMessage") then
                XLuaUiManager.Open("UiMoeWarMessage")
            end
            --XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_ANIMATION_TEST, roleIndex, animName)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_ANIMATION_TEST, roleIndex, animName)
        end
    )
    ---------萌战动画 end------------
end

local function AddSvnFunction()
    local tool = CS.XExternalTool
    local runSvn = tool.RunSvn
    local asynRunTool = asynTask(tool.RunToolInNewThread)
    local svnGuiTool = "TortoiseProc.exe"
    local svnTool = tool.SvnPath

    local checkRevCmd = "info --show-item last-changed-revision "
    local log = XUiManager.TipMsgEnqueue
    local manualResolveTip = function()
        log("如果弹窗有红色列表，请手动解决冲突。如无则请手动关闭")
    end

    Panel:AddButton(
        "更新资源包",
        function()
            RunAsyn(
                function()
                    log("开始更新打包机已打包资源")
                    local oldRev = runSvn(checkRevCmd .. tool.ProductPath .. "File")
                    asynRunTool(svnTool, "cleanup " .. tool.ProductPath .. "File", false)
                    asynRunTool(svnTool, "update --accept tf " .. tool.ProductPath .. "File", false)

                    local newRev = runSvn(checkRevCmd .. tool.ProductPath .. "File")
                    if oldRev ~= newRev then
                        --manualResolveTip()
                        --asynRunTool(svnGuiTool,"/command:resolve /path:"..tool.ProductPath.."File", true)
                        if XLoginManager.IsLogin() then
                            XLuaUiManager.RunMain()
                        else
                            ReLogin()
                        end
                        log("资源有更新，已自动重载并返回主界面")
                    else
                        log("资源无更新，版本号：" .. tonumber(newRev))
                    end

                    local info = runSvn("log -l 1 --incremental " .. tool.ProductPath .. "File")
                    XUiManager.UiFubenDialogTip("打包机最近打包时间", info)
                end
            )
        end
    )

    Panel:AddButton(
        "更新Lua",
        function()
            local oldRev = runSvn(checkRevCmd .. tool.ProductPath .. "Lua")
            runSvn("update --accept mf " .. tool.ProductPath .. "Lua")
            local newRev = runSvn(checkRevCmd .. tool.ProductPath .. "Lua")
            if oldRev ~= newRev then
                ReLogin()
                local info = runSvn("log -l 10 --incremental " .. tool.ProductPath .. "Lua")
                XUiManager.UiFubenDialogTip(CS.XTextManager.GetText("TipTitle"), "--Lua有更新，已自动热重载并重登，以下是更新记录\n" .. info)
            else
                log("Lua无更新，版本号：" .. tonumber(newRev))
            end
        end
    )

    Panel:AddButton(
        "更新配置表",
        function()
            RunAsyn(
                function()
                    log("开始更新配置表")
                    local oldRev = runSvn(checkRevCmd .. tool.ProductPath .. "Table")
                    asynRunTool(svnTool, "cleanup " .. tool.ProductPath .. "Table", false)
                    asynRunTool(svnTool, "update --non-interactive " .. tool.ProductPath .. "Table", false)

                    local newRev = runSvn(checkRevCmd .. tool.ProductPath .. "Table")
                    if oldRev ~= newRev then
                        manualResolveTip()
                        asynRunTool(svnGuiTool, "/command:resolve /path:" .. tool.ProductPath .. "Table", true)

                        CS.XDebugManager.ReloadLuaTable()
                        local info = runSvn("log -l 15 --incremental " .. tool.ProductPath .. "Table")

                        XUiManager.UiFubenDialogTip("更新记录", info)
                        log("配置表有更新，已自动重载并重登，请查看近期更新记录")
                    else
                        log("配置表无更新，版本号：" .. tonumber(newRev))
                    end
                end
            )
        end
    )
end

local function AddArchiveFunction()
    Panel:AddSubMenu("SVN操作\n(beta)", AddSvnFunction)
    --Panel:AddSubMenu("萌战相关", AddMoeWar)
    Panel:AddButton(
        "开启活动",
        function()
            OpenActivity()
        end
    )

    Panel:AddButton(
        "模拟Android",
        function()
            XUserManager.Platform = XUserManager.PLATFORM.Android
        end
    )

    Panel:AddButton(
        "模拟iOS",
        function()
            XUserManager.Platform = XUserManager.PLATFORM.IOS
        end
    )

    Panel:AddButton(
        "简单分享文字2",
        function()
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
        end
    )

    Panel:AddButton(
        "分享文字",
        function()
            XPlatformShareManager.ShareByPlatformShareId(
                platformType,
                function(a)
                    XLog.Debug("share status is ", a)
                end,
                1,
                isShowUi
            )
        end
    )

    Panel:AddButton(
        "分享链接",
        function()
            XPlatformShareManager.ShareByPlatformShareId(
                platformType,
                function(a)
                    XLog.Debug("share status is ", a)
                end,
                2,
                isShowUi
            )
        end
    )

    Panel:AddButton(
        "分享图片",
        function()
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
                XPlatformShareManager.Share(
                    XPlatformShareConfigs.ShareType.Image,
                    platformType,
                    function(a)
                        XLog.Debug("share status is ", a)
                    end,
                    fileFullPath,
                    nil,
                    nil,
                    nil,
                    isShowUi
                )
            else
                XLog.Debug("dirPath is nil")
            end
        end
    )

    Panel:AddButton(
        "打印平台",
        function()
            XLog.Debug("AppPackageName = " .. CS.XAppPlatBridge.GetAppPackageName())
        end,
        3
    )
end

local function AddInfo()
    Panel:AddText(
        "当前服务器",
        function(TxtServer)
            TxtServer.text = string.format("当前服务器\n<color=#F90000FF>%s</color>", XServerManager.GetCurServerName())
        end
    )
    TxtVersion = Panel:AddText("当前版本", UpdateVersionInfo)
    Panel:AddText(
        "已启动时间",
        function(TxtTime)
            TxtTime.text =
                string.format(
                "已启动时间\n<color=#6BFF00>%s</color>",
                XUiHelper.GetTime(
                    math.floor(CS.UnityEngine.Time.realtimeSinceStartup),
                    XUiHelper.TimeFormatType.DAILY_TASK
                )
            )
        end
    )
    Panel:AddText(
        "用户名",
        function(TxtUsername)
            TxtUsername.text = string.format("用户名\n<color=#48E0F0>%s</color>", XUserManager.UserName or "未登录")
        end
    )
end

local function AddServerFunction()
    local version = 0
    Panel:AddInput(
        CS.XInfo.Version,
        function(value)
            version = value
        end
    )
    Panel:AddButton(
        "改版本号",
        function()
            local reset = version == ""
            local newVersion = reset and CS.XInfo.Version or version
            CS.XRemoteConfig.SetVersion(newVersion)
            UpdateVersionInfo()
            if newVersion == "1.0.0" then
                XUiManager.TipMsgEnqueue("版本号被改为" .. newVersion .. '主干!(主干1.0.0，或不填重置)')
            else
                XUiManager.TipMsgEnqueue("版本号被改为" .. newVersion .. "分支!(主干1.0.0，或不填重置)")
            end
        end
    )
    Panel:AddButton(
        "重置版本号(远程配置)",
        function()
            CS.XUriPrefix.LocalMode = false
            XUiManager.TipMsg("正在重置远程配置")
            CS.XRemoteConfig.Reset()
            XScheduleManager.ScheduleOnce(
                function()
                    XServerManager.Init()
                    XUiManager.TipMsgEnqueue("版本号被改为" .. CS.XRemoteConfig.ApplicationVersion)
                    UpdateVersionInfo()
                end,
                2200
            )
        end
    )

    local tool = CS.XExternalTool
    if not tool or type(tool.ProductPath) == "table" then
        return
    end
    local serverPath = tool.ProductPath .. "Bin/NewServer/Bin/"
    Panel:AddButton(
        "开启/重启本地服",
        function()
            tool.RunToolInNewThread(serverPath .. "Start.bat", nil, true)
        end
    )

    Panel:AddButton(
        "关闭本地服",
        function()
            tool.RunToolInNewThread(serverPath .. "Stop.bat", nil, true)
        end
    )

    Panel:AddButton(
        "本地服清库",
        function()
            XUiManager.SystemDialogTip(
                CS.XTextManager.GetText("TipTitle"),
                "是否确定进行清库操作？\n操作后将无法恢复！",
                XUiManager.DialogType.Normal,
                nil,
                function()
                    tool.RunToolInNewThread(serverPath .. "ClearDb.bat", nil, true)
                end
            )
        end
    )
end

local function AddDebugUse()
    local uiName = "UiSet"
    Panel:AddInput(
        "界面名称",
        function(value)
            uiName = value
        end
    )

    Panel:AddButton(
        "打开界面",
        function()
            Open(uiName)
        end
    )

    Panel:AddButton(
        "重载Ui配置表",
        function()
            CS.XUiManager.Instance:Reset()
            ReLogin()
        end
    )
    ---------新增临时服 begin------------
    local ip
    Panel:AddInput(
        "临时服IP:",
        function(value)
            ip = tostring(value)
        end
    )

    Panel:AddButton(
        "新增临时服",
        function()
            local result, desc = XServerManager.InsertTempServer(ip)
            if not result then
                XUiManager.TipMsg(desc)
            else
                XUiManager.TipMsg("成功")
            end
        end
    )
    ---------新增临时服 end------------

    local keyWord
    Panel:AddInput(
        "协议关键字",
        function(value)
            keyWord = value
        end
    )

    Panel:AddButton(
        "添加协议关键字",
        function()
            if string.IsNilOrEmpty(keyWord) then
                XUiManager.TipMsg("请输入网络协议关键字")
            else
                table.insert(XRpc.DebugKeyWords, keyWord)
                XUiManager.TipMsg("添加成功，实用功能中开启网络调试日志即可查看")
            end
        end
    )

    Panel:AddButton(
        "清空协议关键字",
        function()
            XRpc.DebugKeyWords = {}
        end
    )

    Panel:AddButton(
        "替换进战Loading界面",
        function()
            XDataCenter.FubenManager.OpenFightLoading = function()
                XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LOADINGFINISHED)
                local XArchiveCGEntity = require("XEntity/XArchive/XArchiveCGEntity")
                XLuaUiManager.Open("UiArchiveCGDetail", {XArchiveCGEntity.New(106013)}, 1)
            end

            XDataCenter.FubenManager.CloseFightLoading = function()
                XLuaUiManager.Remove("UiArchiveCGDetail")
            end

            XUiManager.TipMsg("进战界面替换成spine动画成功，重登后恢复")
        end
    )

    Panel:AddButton("hotfix镜头刷新", function()
        xlua.hotfix(CS.XCamera, 'Update', function() end)
    end)

    Panel:AddButton("还原镜头刷新", function()
        xlua.hotfix(CS.XCamera, 'Update', CS.XCamera.Update)
    end)
end

local function AddTestUse()
    local guideId = 50102
    Panel:AddInput(
        "引导Id",
        function(value)
            guideId = tonumber(value)
        end
    )

    Panel:AddButton(
        "开启引导(强制)",
        function()
            XDataCenter.GuideManager:PlayGuide(guideId)
        end
    )

    Panel:AddButton(
        "开启引导",
        function()
            local guide = XGuideConfig.GetGuideGroupTemplatesById(guideId)
            XDataCenter.GuideManager.TryActiveGuide(guide)
        end
    )

    Panel:AddButton(
        "关闭新手引导",
        function()
            XDataCenter.GuideManager.ResetGuide()
        end
    )

    ---------UI遮罩测试 begin------------
    local maskTime = 0
     --遮罩计时
    local timeId = nil

    local txtMaskTime = Panel:AddText(string.format("距离上一次遮罩计时:<color=#F90000FF>%d</color>秒", maskTime))

    local updateTxt = function()
        if XTool.UObjIsNil(txtMaskTime) then
            return
        end
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
        timeId =
            XScheduleManager.ScheduleForever(
            function()
                if XTool.UObjIsNil(txt) then
                    reset()
                    return
                end
                maskTime = maskTime + 1
                updateTxt()
            end,
            XScheduleManager.SECOND
        )
    end

    Panel:AddButton(
        "添加UI遮罩",
        function()
            reset()
            updateTxt()
            addTimer()
            XLuaUiManager.SetMask(true)
        end
    )

    Panel:AddButton(
        "取消UI遮罩",
        function()
            updateTxt()
            XLuaUiManager.SetMask(false)
        end
    )
    ---------UI遮罩测试 end------------
    ---------LUA内存 begin------------
    Panel:AddButton(
        "开始记录LUA内存",
        function()
            XLuaMemoryMonitor.StartRecordAlloc()
        end
    )

    Panel:AddButton(
        "结束记录LUA内存",
        function()
            XLuaMemoryMonitor.StopRecordAlloc()
        end
    )
    ---------LUA内存 end------------

    ---------帧率 begin------------
    local frameDefault = 5
    local frame = tostring(frameDefault)
    Panel:AddInput(
            tostring(frameDefault),
            function(value)
                frame = value
            end
    )
    Panel:AddButton(
            "改帧率",
            function()
                local reset = frame == ""
                local newFrame = reset and frameDefault or frame
                CS.UnityEngine.Application.targetFrameRate = newFrame
                local frameRate = CS.XGraphicManager.RenderConst.QualitySettingsData.FrameRate
                frameRate.HigherFrameRate = newFrame
                frameRate.HighestFrameRate = newFrame
                frameRate.MiddleFrameRate = newFrame
                frameRate.LowFrameRate = newFrame
                frameRate.HighFrameRate = newFrame
                UpdateVersionInfo()
                XUiManager.TipMsgEnqueue("帧率被改为" .. newFrame)
            end
    )
    Panel:AddButton(
            "60帧",
            function()
                local newFrame = 60
                CS.UnityEngine.Application.targetFrameRate = newFrame
                local frameRate = CS.XGraphicManager.RenderConst.QualitySettingsData.FrameRate
                frameRate.HigherFrameRate = newFrame
                frameRate.HighestFrameRate = newFrame
                frameRate.MiddleFrameRate = newFrame
                frameRate.LowFrameRate = newFrame
                frameRate.HighFrameRate = newFrame
                XUiManager.TipMsgEnqueue("帧率被改为" .. newFrame)
            end
    )
    ---------帧率 end------------
    
    ---------机器人配置调试 begin------------
    --[[    
    显示武器共鸣技能、意识共鸣技能、意识超频技能增加的生命/会心/防御/攻击数值
    显示成员当前的战斗力
    显示伙伴当前的战力、攻击力数值
    ]]
    local robotId = 0
    Panel:AddInput(
        "机器人Id",
        function(value)
            robotId = tonumber(value)
        end
    )

    Panel:AddButton(
        "查看机器人数据",
        function()
            if not XTool.IsNumberValid(robotId) then
                XUiManager.TipMsg("请先输入robotId!")
                return
            end

            if not XRobotManager.CheckRobotExist(robotId) then
                XUiManager.TipMsg(
                    "robotId不正确，找不到对应配置，robotId: " .. robotId .. ", 配置路径: " .. XRobotManager.GetConfigPath()
                )
                return
            end

            local partner = XRobotManager.GetRobotPartner(robotId)
            local partnerAttr = not XTool.IsTableEmpty(partner) and partner:GetPartnerAttrMap(partner:GetLevel())
            local equipResonanceAttr = XRobotManager.GetRobotResonanceAbilityList(robotId)
            local equipAwakenAttr = XRobotManager.GetRobotAwakenAbilityList(robotId)

            local content =
                string.format(
                [[
                机器人战力: %d\n
                机器人伙伴战力: %d\n
                机器人伙伴攻击力: %d\n
                武器/意识共鸣增加属性值: %s\n
                意识超频增加属性值: %s\n
                ]],
                XRobotManager.GetRobotAbility(robotId),
                XRobotManager.GetRobotPartnerAbility(robotId),
                not XTool.IsTableEmpty(partnerAttr) and partnerAttr[1].Value or 0,
                not XTool.IsTableEmpty(equipResonanceAttr) and "详见LOG" or "空",
                not XTool.IsTableEmpty(equipAwakenAttr) and "详见LOG" or "空"
            )
            XUiManager.UiFubenDialogTip("机器人数据", content)
            if not XTool.IsTableEmpty(equipResonanceAttr) then
                XLog.Debug("机器人Id: " .. robotId .. ", 武器/意识共鸣增加属性值: ", equipResonanceAttr)
            end
            if not XTool.IsTableEmpty(equipAwakenAttr) then
                XLog.Debug("机器人Id: " .. robotId .. ", 意识超频增加属性值: ", equipAwakenAttr)
            end
        end
    )

    local XRobot = require("XEntity/XRobot/XRobot")
    XRobot.New(1001)
    ---------机器人配置调试 end------------
end

local function AddActivityUse() 
    
    Panel:AddToggle(
            "全境性能测试", function(value) 
                XDataCenter.AreaWarManager.SetPerformanceTesting(value)
            end
    )
end

local function AddPlannerUse()
    

    local skipId
    Panel:AddInput(
        "Skip跳转Id",
        function(value)
            skipId = tonumber(value)
        end
    )

    Panel:AddButton(
        "开始跳转",
        function()
            if skipId then
                XFunctionManager.SkipInterface(tonumber(skipId))
            else
                XUiManager.TipMsg("请输入正确的SkipId后操作")
            end
        end
    )

    Panel:AddButton(
            "连线教学导出",
            function()
                -- 导出上一次游戏纪录，成为图文教学配置
                XMVCA.XLineArithmetic:SaveCurrentGameData2Config()
            end
    )
end

local function AddFightUse()
    local uiName = "UiMultiDimFight"
    Panel:AddInput(
            "界面名称",
            function(value)
                uiName = value
            end
    )

    Panel:AddButton(
        "打开战斗界面",
        function()
            local fight = CS.XFight.Instance
            if not fight then
                return
            end

            fight.UiManager:GetUi(typeof(CS.XUiFight)):OpenChildUi(uiName, fight)
        end
    )
end

local function AddGuildDormUse()
    Panel:AddToggle("键盘操作", function(res)
        XGuildDormConfig.DebugKeyboard = res
    end)
    Panel:AddToggle("模拟延迟", function(res)
        XGuildDormConfig.DebugNetworkDelay = res
    end)
    Panel:AddInput("最小延迟(毫秒)", function(value)
        XGuildDormConfig.DebugNetworkDelayMin = value
    end)
    Panel:AddInput("最大延迟(毫秒)", function(value)
        XGuildDormConfig.DebugNetworkDelayMax = value
    end)
    Panel:AddToggle("模拟断线重连（按R键）", function(res)
        XGuildDormConfig.DebugOpenReconnect = res
    end)
    Panel:AddToggle("模拟玩家人数(需重进)", function(res)
        XGuildDormConfig.DebugFullRole = res
    end)
    Panel:AddInput("玩家数量", function(value)
        XGuildDormConfig.DebugFullRoleCount = value
    end)
    Panel:AddToggle("重新生成导航障碍", function(res)
        XDataCenter.GuildDormManager.ResetRoomNavmeshObstacle()
    end)
    Panel:AddToggle("切换新旧公会入口", function(res)
        XGuildDormConfig.DebugOpenOldUi = res
    end)
end

local function AddDlcUse()
    Panel:AddButton("提前结算", function()
        XFightNetwork.Call("DlcCheatRequest", { Content = "advance_settlement" }, function(res)
            if res.Code ~= XCode.Success then
                XLog.Error("DlcCheatResponse is Not Success! Error Code:" .. tostring(res.Code))
                return
            end
        end)
    end)
    Panel:AddInput("自定义内容", function(value)
        XFightNetwork.Call("DlcCheatRequest", { Content = tostring(value) }, function(res)
            if res.Code ~= XCode.Success then
                XLog.Error("DlcCheatResponse is Not Success! Error Code:" .. tostring(res.Code))
                return
            end
        end)
    end)
    Panel:AddButton("猫鼠游戏", function()
        XMVCA.XDlcMultiMouseHunter:OpenMainUi()
    end)
end

-- 日志打印
local function AddLogFunction()
    Panel:AddButton("开启日志打印", function()
        XEnumConst.RogueSim.IsDebug = true
        XEnumConst.Theatre4.IsDebug = true
    end)
    Panel:AddButton("关闭日志打印", function()
        XEnumConst.RogueSim.IsDebug = false
        XEnumConst.Theatre4.IsDebug = false
    end)
end

-- 节奏游戏
local function AddRhythmGameFunction()
    local rhythmMapId = 0
    local playerOffset = 0
    Panel:AddInput(
        "谱面Id(数字)",
        function(value)
            rhythmMapId = tonumber(value)
        end
    )
    Panel:AddInput(
        "Offset",
        function(value)
            playerOffset = tonumber(value)
        end
    )
    Panel:AddButton("进入关卡", function()
        XMVCA.XRhythmGame:EnterGame(rhythmMapId, playerOffset or 0, true)
		XEventManager.DispatchEvent(XEventId.EVENT_RHYTHM_TAIKO_ANIMSHOW, true)
    end)
end

-- 音频调试
local function AddAudioDebugFunction()
    local cueId
    local typeId
    Panel:AddInput(
        "音频类型",
        function(value)
            typeId = tonumber(value)
        end
    )

    Panel:AddInput(
        "CueId",
        function(value)
            cueId = tonumber(value)
        end
    , true)

    local btnPlay =
        Panel:AddButton(
        "播放音频",
        function()
            if not cueId or not typeId then
                XUiManager.TipMsg("请填写音频类型（1->BGM、2->音效、4->CV）和CueId后使用，例如填写2、1020将播放进入战斗音效")
                return
            end

            if not XLuaAudioManager.PlayFunc[typeId] then
                XUiManager.TipMsg("不存在音频类型"..typeId.."，请检查是否填写正确")
                return
            end
            XLuaAudioManager.PlayAudioByType(typeId, cueId)
        end
    )

    if btnPlay then
        btnPlay.transform:GetComponent("XUguiPlaySound").enabled = false
    end

    Panel:AddButton(
        "关闭音频",
        function()
            XLuaAudioManager.StopAll()
        end
    )

    Panel:AddButton(
        "音频日志收集",
        function()
            if not CS.XAudioManager.IsLogCollect then
                CS.XAudioManager.SetIsLogCollect()
            end
        end
    )

    Panel:AddButton(
        "音频日志文件生成",
        function()
            if not CS.XAudioManager.IsGenerateLogFile then
                CS.XAudioManager.StartGenerateLogFile()
            else
                CS.XAudioManager.StopGenerateLogFile()
            end
            
        end
    )

    Panel:AddToggle(
        "打印播放音频日志",
        function()
            CS.XAudioManager.SetIsAudioPlayLogInConsole()
        end
    )

    Panel:AddToggle(
        "打印停止音频日志",
        function()
            CS.XAudioManager.SetIsAudioStopLogInConsole()
        end
    )

    Panel:AddToggle(
        "打印选择器日志",
        function()
            CS.XAudioManager.SetIsSelectorLogInConsole()
        end
    )

    Panel:AddToggle(
        "打印Aisac日志",
        function()
            CS.XAudioManager.SetIsAisacLogInConsole()
        end
    )

    Panel:AddButton(
        "打印音量信息",
        function()
            XLuaAudioManager.PrintVolumeInfo()
        end
    )

    Panel:AddButton(
        "音频配置重载",
        function()
            CS.XAudioManager.InitConfig()
        end
    )

    local isInitBwData = false
    Panel:AddToggle(
        "加载/卸载Bw音频配置",
        function()
            if not isInitBwData then
                CS.XAudioManager.InitBwAudioData()
            else
                CS.XAudioManager.ClearBwAudioData()
            end
        end
    )
end

-- 视频调试
local function AddVideoDebugFunction()
    local videoId
    Panel:AddInput(
        "VideoId:",
        function(value)
            videoId = tonumber(value)
        end
    )

    Panel:AddButton(
        "播放视频",
        function()
            if videoId then
                local fight = CS.XFight.Instance
                XLog.Debug("PlayVideo " .. (fight and "In Fight" or "") .. ", VideoId:" .. tostring(videoId), type(videoId))
                if fight then
                    local uiFightVideoPlayer = fight.UiManager:GetUi(typeof(CS.XUiFightVideoPlayer))
                    if uiFightVideoPlayer == nil then
                        fight.UiManager:GetUi(typeof(CS.XUiFight)):OpenChildUi("UiFightVideoPlayer", fight)
                        uiFightVideoPlayer = fight.UiManager:GetUi(typeof(CS.XUiFightVideoPlayer))
                    end
                    uiFightVideoPlayer:PlayVideo(videoId, 0)
                else
                    XDataCenter.VideoManager.PlayUiVideo(videoId, nil, true, true)
                end
            end
        end
    )

    Panel:AddButton(
        "单次打印视频日志",
        function()
            CS.XVideoManager.PrintAllVideoUguiInfo(true)
        end
    )

    Panel:AddToggle(
        "每帧打印视频日志",
        function()
            CS.XVideoManager.SetIsUpdateDebugAllVideoUguiInfo()
        end
    )

    Panel:AddToggle(
        "监听视频状态",
        function()
            CS.XVideoManager.SetIsLogVideoStatusEventInfo()
        end
    )

    Panel:AddToggle(
        "监听视频操作",
        function()
            CS.XVideoManager.SetIsLogVideoActionEventInfo()
        end
    )

    Panel:AddButton(
        "(当前视频)Play",
        function()
            local videoUgui = CS.XVideoManager.GetLastAddVideoUgui()
            videoUgui:Play()
        end
    )

    Panel:AddButton(
        "(当前视频)RePlay",
        function()
            local videoUgui = CS.XVideoManager.GetLastAddVideoUgui()
            videoUgui:RePlay()
        end
    )

    Panel:AddButton(
        "(当前视频)Stop",
        function()
            local videoUgui = CS.XVideoManager.GetLastAddVideoUgui()
            videoUgui:Stop()
        end
    )

    Panel:AddButton(
        "(当前视频)Pause",
        function()
            local videoUgui = CS.XVideoManager.GetLastAddVideoUgui()
            videoUgui:Pause()
        end
    )

    Panel:AddButton(
        "(当前视频)Resume",
        function()
            local videoUgui = CS.XVideoManager.GetLastAddVideoUgui()
            videoUgui:Resume()
        end
    )
end

local function AddGame2048DebugFunction()
    local isInit = true
    ---@type UnityEngine.UI.Toggle
    local debugTog = Panel:AddToggle("启用Debug", function(res)
        if isInit then
            return
        end
        
        XSaveTool.SaveData('Game2048Debug', res)

        if res then
            XLog.Error('2048玩法开启Debug，需重进游戏生效')
        else
            XLog.Error('2048玩法关闭Debug，需重进游戏生效')
        end
    end)

    if debugTog then
        debugTog.isOn = XSaveTool.GetData('Game2048Debug')
    end

    debugTog = Panel:AddToggle("始终录制", function(res)
        if isInit then
            return
        end
        
        XSaveTool.SaveData('Game2048RecordEnable', res)

        if res then
            XLog.Error('2048玩法开启始终录制(每次开始新的游戏自动开启录制，结算后自动结束录制），需重进游戏生效')
        else
            XLog.Error('2048玩法关闭始终录制，需重进游戏生效')
        end
    end)

    if debugTog then
        debugTog.isOn = XSaveTool.GetData('Game2048RecordEnable')
    end
    
    Panel:AddButton("手动开始录制", function()
        if isInit then
            return
        end
        
        XMVCA.XGame2048:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_START_RECORD)
    end)
    
    Panel:AddButton("手动结束录制", function()
        if isInit then
            return
        end
        
        XMVCA.XGame2048:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_END_RECORD)
    end)
    
    local fullname = ''
    
    Panel:AddInput("回放文件名", function(filename)
        if string.IsNilOrEmpty(filename) then
            return
        end

        if isInit then
            return
        end
        
        fullname = CS.XLaunchManager.ProductPath..'/ReplayFight/Game2048RecordData/'..tostring(filename)..'.lua'
    end)
    
    Panel:AddButton("执行回放", function()
        if isInit then
            return
        end
        
        if not CS.System.IO.File.Exists(fullname) then
            XLog.Error('2048玩法回放文件不存在:', fullname)
        else
            if XLuaUiManager.IsUiShow('UiGame2048Game') then
                XMVCA.XGame2048:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_LOAD_RECORD_DATA, fullname)
            else
                XLog.Error('请在玩法界面内回放')
            end
        end
    end)

    isInit = false
end

local function AddSubPackageFunction()
    Panel:AddButton("Item信息", function()
        local resItemDic, subpackageItemDic = XMVCA.XSubPackage:GetAllResAndSubpackageItemDic()
        local resItemString = "[分包Info Item数据]\nResInfo\n"
        local subPackageItemString = "\nSubpackageInfo\n"

        for _, item in pairs(resItemDic) do
            local formatted = string.format("ResId:%d, State:%d, TaskGropState:%s, DownloadSize:%d, TotalSize:%d, 进度:%s\n", 
            item._Id, item:GetState(), item:GetTaskGroup().State, item:GetDownloadSize(), item:GetTotalSize(), item:GetProgress())

            resItemString = resItemString .. formatted
        end

        for _, item in pairs(subpackageItemDic) do
            local formatted = string.format("SubpackageId:%d, State:%d, DownloadSize:%d, TotalSize:%d, 进度:%s\n", item._Id, item:GetState(), item:GetDownloadSize(), item:GetTotalSize(), item:GetProgress())
            subPackageItemString = subPackageItemString .. formatted
        end

        XLog.Warning(resItemString .. subPackageItemString)
    end)

    Panel:AddButton("队列信息", function()
        local resQueue = XMVCA.XSubPackage._ResWaitDnLdQueue
        local subpackageQueue = XMVCA.XSubPackage._SubpackageWaitDnLdQueue
        XLog.Warning("[分包Info 队列数据]\nRes队列\n", resQueue,"\nSubPackage队列\n", subpackageQueue)
    end)

    local ResId
    Panel:AddInput(
        "ResId:",
        function(value)
            ResId = tonumber(value)
        end
    )

    Panel:AddButton("下载ResId", function()
        XMVCA.XSubPackage:AddResToDownload(ResId)
    end)

    local SubPackageId
    Panel:AddInput(
        "SubPackageId:",
        function(value)
            SubPackageId = tonumber(value)
        end
    )

    Panel:AddButton("下载SubPackageId", function()
        XMVCA.XSubPackage:AddToDownload(SubPackageId)
    end)
end

--------------Ui组件创建 begin----------------
function XGmTestManager.Init()
    Panel = CS.XDebugManager.DebuggerGm
    Panel:AddSubMenu("本地测试", XGmTestManager.TestFunc)
    Panel:AddSubMenu("当前信息", AddInfo, true)
    Panel:AddSubMenu("服务器", AddServerFunction, true)
    Panel:AddSubMenu("开发专用", AddDebugUse)
    Panel:AddSubMenu("测试专用", AddTestUse)
    Panel:AddSubMenu("活动测试", AddActivityUse)
    Panel:AddSubMenu("策划专用", AddPlannerUse)
    Panel:AddSubMenu("归档功能", AddArchiveFunction)
    Panel:AddSubMenu("战斗测试", AddFightUse)
    Panel:AddSubMenu("公会宿舍", AddGuildDormUse)
    Panel:AddSubMenu("DLC测试", AddDlcUse)
    Panel:AddSubMenu("日志打印", AddLogFunction)
    --Panel:AddButton("庙会", function()
    --    XLuaUiManager.Open("UiTempleBattleEditor")
    --end)
    --Panel:AddButton("庙会2", function()
    --    XLuaUiManager.Open("UiTemple2Editor")
    --end)
    Panel:AddButton("幸运租客", function()
        XLuaUiManager.Open("UiLuckyTenantGame")
    end)
    --[[Panel:AddButton("背包整理", function()
        if not XLuaUiManager.IsUiShow('UiBagOrgnizeEditor') then
            XLuaUiManager.Open("UiBagOrgnizeEditor")
        end
    end)--]]

    Panel:AddSubMenu("节奏游戏", AddRhythmGameFunction)
    Panel:AddSubMenu("音频调试", AddAudioDebugFunction)
    Panel:AddSubMenu("视频调试", AddVideoDebugFunction)
    
    Panel:AddSubMenu("2048玩法", AddGame2048DebugFunction)
    Panel:AddSubMenu("分包调试", AddSubPackageFunction)

    local isInit = true
    local skipRecordTog = Panel:AddToggle("通用跳转埋点测试", function(isOn)
        if isInit then
            return
        end
        
        XFunctionManager.__RecordTestEnable = isOn
    end)
    
    skipRecordTog.isOn = XFunctionManager.__RecordTestEnable
    
    isInit = false

end
--------------Ui组件创建 end----------------

function XGmTestManager.TestFunc()
    --XLoginManager.ResetHearbeatInterval()
    XLoginManager.SpeedUpHearbeatInterval()
do return end
    local DocumentFilePath = CS.UnityEngine.Application.persistentDataPath .. "/document"
    local files = CS.XFileTool.GetFiles(DocumentFilePath .. "/" .. "matrix")
    local appFiles = CS.XFileTool.GetFiles(DocumentFilePath .. "/" .. "launch")
    local filesLength = files.Length
    local appFilesLength = appFiles.Length
    local INDEX = "index"
    XLog.Debug("11 files:" .. filesLength .. ",files：", files)
    XLog.Debug("11 appFiles:" .. appFilesLength)
    -- files:AddRangeWithoutGC(appFiles)
    -- XLog.Debug("22 files:" .. filesLength)
    local UpdateTable = {}
    local length = filesLength + appFilesLength
    -- for index = 0, length - 1 do
    for i = 0, length - 1 do
        -- local i = index
        local file
        if i < filesLength then
            file = files[i]
            print("111 i: " .. tostring(i) .. ", " .. file)
            local name = CS.XFileTool.GetFileName(file)
            UpdateTable[name] = true
        else
            i = i - filesLength -- 此处i会在迭代器中被重新复制
            file = appFiles[i]
            print("222 i: " .. tostring(i) .. ", " .. file)
        end
    end

    XLog.Debug("UpdateTable", UpdateTable)
    
    for i = 0, appFilesLength - 1 do
        local file = appFiles[i]
        local name = CS.XFileTool.GetFileName(file)
        print("i :" .. tostring(i)..", name:" .. name .. ", file:" .. file)
        if name == INDEX then
            goto CONTINUE
        end

        local info = UpdateTable[name] -- 更新文件已存在
        if info then
            print("已经更新：" .. name)
            goto CONTINUE
        end
        :: CONTINUE ::
    end

do return end
    local CsTool = CS.XTool
    local CsApplication = CS.XApplication
    local CsGameEventManager = CS.XGameEventManager.Instance
    local cb = function()end
    local documentPath = CS.UnityEngine.Application.persistentDataPath .. "/document"
    -- string.Utf8Len
    
    local files = CS.System.IO.Directory.GetFiles(documentPath, "*.zip", CS.System.IO.SearchOption.TopDirectoryOnly)
    print("[Unzip] DocumentPath:" .. tostring(documentPath) .. ", files.length:" .. tostring(files.Length))
    local length = files.Length
    local function UnzipFile(index)
        if index >= length then
            if index > 0 then
                CsApplication.SetProgress(1)
                print("[Unzip] Finished.")
            end
            cb()
            return
        end
        local file = files[index]
        local nextIndex = index + 1
        if string.find(file, "_resource") then
            local overwrite = true
            local password = nil
            local totalCount = CS.ZipUtility.GetZipEntityCount(file, password)
            print("[Unzip] Start File: " .. tostring(file))

            if (totalCount > 0) then
                local cancelCB = function()
                    UnzipFile(nextIndex)
                end
                local confirmCB = function()
                    local needUnit = false
                    CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD, totalCount, needUnit)
                    CsApplication.SetProgress(0)

                    local progressCB = function(counter, name)
                        local progress = counter / totalCount
                        CsApplication.SetProgress(progress)

                        print("[Unzip]  progress:" .. tostring(counter) .. "/" .. tostring(totalCount) .. ", name:" .. tostring(name) .. ", zipFile: " .. tostring(file) .. ", outputPath:" .. tostring(documentPath))
                    end

                    local finishCB = function(counter)
                        if counter >= totalCount then
                            print("[Unzip] Completed file:" .. tostring(file))
                            CS.XFileTool.DeleteFile(file)
                            UnzipFile(nextIndex)
                        end
                    end
                    CS.ZipUtility.UnzipFile(file, documentPath, progressCB, finishCB, overwrite, password)
                end
                local text = "检查到本地压缩文件" .. CS.XFileTool.GetFileNameWithoutExtension(file) .. ", 是否进行解压?"
                CsTool.WaitCoroutine(CsApplication.CoDialog(CsApplication.GetText("Tip"), text, cancelCB, confirmCB))
            else
                print("[Unzip] count <= 0, zipFile: " .. tostring(file))
                UnzipFile(nextIndex)
            end
        else
            print("[Unzip] name not Contains '_resource', zipFile: " .. tostring(file))
            UnzipFile(nextIndex)
        end
    end
    local index = 0
    UnzipFile(index)
end

--region Replay - 回放自动化测试相关 by标仔 2024.05.07
function XGmTestManager.GetBeReplayFileListByCount(count)
    local dataList = {}
    local csDataList = CS.Debugger.XDebuggerReplay.LuaCallGetBeReplayFileList()
    for i = 0, csDataList.Length-1 do
        if i < count or count < 0 then
            table.insert(dataList, csDataList[i])
        end
    end
    return dataList
end
--endregion