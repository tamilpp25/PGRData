local Creator = function()
    local XUiLaunchUi = {}

    local XDynamicTableCurveLaunch = require("XLaunchUi/XDynamicTableCurveLaunch")
    local DYNAMIC_DELEGATE_EVENT = XDynamicTableCurveLaunch.DYNAMIC_DELEGATE_EVENT
    local XLaunchDlcManager = require("XLaunchDlcManager")
    local Vector3 = CS.UnityEngine.Vector3
    local MathFloor = math.floor
    local StringFormat = string.format
    local IsHideFunc = CS.XRemoteConfig.IsHideFunc
    local IsHideFuncAndroid = CS.XRemoteConfig.IsHideFuncAndroid -- 安卓的提审模式

    --====== XUiLaunchImageGrid ======
    local XUiLaunchImageGrid = {}

    function XUiLaunchImageGrid:Ctor(ui)
        self.ui = ui
        self.Transform = self.ui.transform
        self.GameObject = self.ui.gameObject
        return self
    end

    function XUiLaunchImageGrid:SetData(data)
        local go
        if self.Transform.childCount > 0 then
            go = self.Transform:GetChild(0):LoadPrefab(data)
        else
            go = self.GameObject:LoadPrefab(data)
        end
        self.PrefabGO = go
    end

    function XUiLaunchImageGrid:PlayAnim()
        local go = self.PrefabGO
        go.transform.parent.parent.gameObject:SetActiveEx(true) -- 初次会隐藏，导致无法播放动画
        local animationTrans = go.transform:Find("Animation")
        local directors = go:GetComponentsInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector))
        for i = 0, directors.Length - 1 do
            local directorGO = directors[i].gameObject
            directorGO:SetActiveEx(true)
            directorGO:PlayTimelineAnimation()
        end
    end

    local Split = function(str)
        local arr = {}
        for v in string.gmatch(str, "[^|]*") do
            table.insert(arr, v)
        end
        return arr
    end

    --==========Queue=========--
    local function Enqueue(queue, element)
        if not element then return end

        local endIndex = queue._EndIndex + 1
        queue._EndIndex = endIndex
        queue._Container[endIndex] = element
    end

    local function Dequeue(queue)
        if queue._StartIndex > queue._EndIndex then
            return nil
        end

        local startIndex = queue._StartIndex
        local element = queue._Container[startIndex]

        queue._StartIndex = startIndex + 1
        queue._Container[startIndex] = nil

        return element
    end

    local function Count(queue)
        return queue._EndIndex - queue._StartIndex + 1
    end

    local function NewQueue()
        return
        {
            _Container = {},
            _StartIndex = 1,
            _EndIndex = 0
        }
    end

    --====== XUiLaunch ======
    function XUiLaunchUi:OnAwakeUi()
        self:OnAwake()
    end

    function XUiLaunchUi:OnAwake()
        --强制刷新布局
        if not self.PanelTxt then
            self.PanelTxt = self.TxtDownloadSize.transform.parent
        end
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelTxt)
        self.UiLoading = self.UiLoading.gameObject
        self.UiDownload = self.UiDownload.gameObject
        self.UiVideoPlay = self.UiVideoPlay.gameObject
        self.UiDownlosdTips = self.UiDownlosdTips.gameObject
        self.PanelDialog = self.PanelDialog.gameObject
        self.UiDownlosdTips.transform:SetSiblingIndex(10)

        self.UiLoading:SetActiveEx(false)
        self.UiDownload:SetActiveEx(false)
        self.UiVideoPlay:SetActiveEx(false)
        self.UiDownlosdTips:SetActiveEx(false)
        self.PanelDialog:SetActiveEx(false)

        self.DownloadProgressEffectTrans = nil
        self.DownloadProgressEffect:SetLoadedCallback(function() self:OnEffectLoaded() end)

        self.BtnBasic.CallBack = function() self:OnSelectBasic() end
        if CS.XRemoteConfig.LaunchSelectType == 1 then -- 支持完整下载
            self.BtnAll.CallBack = function() self:OnSelectAllDlc() end
        else
            self.BtnAll.CallBack = nil
            self.BtnAll:SetButtonState(CS.UiButtonState.Disable)
        end
        self.BtnConfirmSelect.CallBack = function() self:OnConfirmSelect() end

        self.VideoPlayerUgui.ActionEnded = function() self:OnVideoEnded() end
        -- self.BtnAuto.CallBack = function() self:OnBtnAutoClick() end
        self.BtnSkipVideo.CallBack = function() self:OnBtnSkipVideoClick() end
        self.BtnVideo.CallBack = function() self:OnBtnVideoClick() end
        self.BtnVideo.gameObject:SetActiveEx(false)
        self.BtnSkipVideo.gameObject:SetActiveEx(false)
        if self.BtnMask then
            self.BtnMask.CallBack = function() self:OnClickBtnMask() end
        end
        self.IsPlayingCG = false
        
        -- self.TxtInfo.text = "当前处于数据网络，预计需要下载860MB的资源，是否继续下载？"
        self.BtnDialogConfirm.CallBack = function() self:OnBtnDialogConfirmClick() end
        self.BtnDialogCancel.CallBack = function() self:OnBtnDialogCancelClick() end
        if self.BtnDialogClose then
            self.BtnDialogClose.CallBack = function() self:OnBtnDialogCancelClick() end
        end

        self.DownloadCostTimeTitle = (CS.XApplication.GetText("DownloadCostTime") or "预计时间") .. "："
        self.DownloadCostTimeTitleDefault = self.DownloadCostTimeTitle .. "00:00:00"

        self.UpdateSize = 0
        self.MBSize = 0
        self.LastUpdateTime = 0
        self.LastProgress = 0

        self.CurrentDownloadSelect = 2
        self.SizeWindow = NewQueue()
        self.TimeWindow = NewQueue()
        self.WindowTimeSum = 0
        self.WindowSizeSum = 0;
        self.WindowSize = 5

        -- 展示列表
        local showPaths = CS.XLaunchManager.LaunchConfig:GetString("UiLaunchShowList") -- 注意：launch更新时只能使用包内资源（还未解析matrix的index文件及资源）
        if not showPaths or showPaths == "null" or IsHideFunc or IsHideFuncAndroid then -- 没轮换图或提审模式下，不显示
            self.DefaultDownloadBG.gameObject:SetActiveEx(true)
            self.PanelList.gameObject:SetActiveEx(false)
            self.BtnLast.gameObject:SetActiveEx(false)
            self.BtnNext.gameObject:SetActiveEx(false)
        else
            self.DefaultDownloadBG.gameObject:SetActiveEx(false)

            local paths = Split(showPaths)
            self.DataList = {}
            for i, path in ipairs(paths) do
                if path and path ~= "" then
                    table.insert(self.DataList, path)
                end
            end
            self.NeedAutoScrollNext = (#self.DataList > 1)
            self.AutoScrollTime = CS.XLaunchManager.LaunchConfig:GetInt("UiLaunchAutoScrollTime")
            -- print("[LaunchTest] UiLaunchShowList:" .. tostring(showPaths) .. ",NeedAutoScrollNext:" .. tostring(self.NeedAutoScrollNext) .. ", AutoScrollTime:" .. self.AutoScrollTime)
            if self.AutoScrollTime == 0 then
                self.AutoScrollTime = 6000
            end
            self.HasScrolled = false

            self.CurrentIndex = 1
            self.DynamicTable = XDynamicTableCurveLaunch.New(self.PanelList)
            self.DynamicTable:SetProxy(XUiLaunchImageGrid)
            self.DynamicTable:SetDelegate(self)
            self.GridPanel.gameObject:SetActiveEx(false)

            self.BtnLast.CallBack = function()
                self.HasScrolled = true
                self.DynamicTable:TweenToIndex((self.CurrentIndex - 1) - 1)
            end

            self.BtnNext.CallBack = function()
                self.HasScrolled = true
                self.DynamicTable:TweenToIndex((self.CurrentIndex - 1) + 1)
            end

            self.AutoScrollNextFunc = function() 
                -- CS.XLog.Debug("====AutoScrollNext currentIndex:" .. self.CurrentIndex ..", HasScrolled:" .. tostring(self.HasScrolled) .. ", self.IsDraggging:" .. tostring(self.IsDraggging))
                if self.IsDraggging  then
                    return
                end
                if self.HasScrolled then
                    self.HasScrolled = false
                    return
                end
                self.DynamicTable:TweenToIndex((self.CurrentIndex - 1) + 1)
            end
        end
    end
    
    function XUiLaunchUi:GetFixIndex(index)
        index = index % #self.DataList
        return index + 1
    end

    function XUiLaunchUi:OnDynamicTableEvent(event, index, grid)
        if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
            local fixIndex = self:GetFixIndex(index)
            grid:SetData(self.DynamicTable.DataSource[fixIndex])
            if fixIndex == self.CurrentIndex then
                grid:PlayAnim()
            end
            -- print(">>>> OnDynamicTableEvent, event:" .. event .. ", index: " .. tostring(index)  ..",fixIndex：" .. tostring(fixIndex) .. ", self.CurrentIndex:" .. tostring(self.CurrentIndex))
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
            if index < 0 then index = self.DynamicTable:GetTweenIndex() end
            self.CurrentIndex = index + 1
            local grid = self.DynamicTable:GetGridByIndex(self.CurrentIndex - 1)
            grid:PlayAnim()
            -- print(">>>>>>>> OnDynamicTableEvent, event:" .. event .. ", index: " .. tostring(index)  ..",fixIndex：" .. tostring(fixIndex) .. ", self.CurrentIndex:" .. tostring(self.CurrentIndex))
            self.IsDraggging = false
        elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
            self.IsDraggging = true
            self.HasScrolled = true -- 跳过下一次自动轮播
        end
    end
    
    function XUiLaunchUi:OnRefresh()
        if self.DynamicTable then
            self.DynamicTable:SetDataSource(self.DataList)
            self.DynamicTable:ReloadData(self.CurrentIndex - 1)
        end
    end

    function XUiLaunchUi:OnStartUi()
        self:OnStart()
    end
    function XUiLaunchUi:OnStart()
        self._IsUseChannelCdn = CS.XUriPrefix.GetIsUseChannelCdn() --是否使用了分渠道cdn
    end

    function XUiLaunchUi:OnEnableUi()
        self:OnEnable()
    end

    function XUiLaunchUi:OnEnable()
        CS.UnityEngine.Screen.sleepTimeout = CS.UnityEngine.SleepTimeout.NeverSleep
    end


    function XUiLaunchUi:CheckAutoScrollTimer()
        if IsHideFunc then
            return
        end
        if self.NeedAutoScrollNext and self.AutoScrollTimerId == nil then
            self:AddAutoScrollTimer()
        end
    end

    function XUiLaunchUi:AddAutoScrollTimer()
        self:RemoveAutoScrollTimer()
        self.AutoScrollTimerId = CS.XScheduleManager.Schedule(self.AutoScrollNextFunc, self.AutoScrollTime, 0)
    end

    function XUiLaunchUi:RemoveAutoScrollTimer()
        if self.AutoScrollTimerId then
            CS.XScheduleManager.UnSchedule(self.AutoScrollTimerId)
            self.AutoScrollTimerId = nil
        end
    end

    function XUiLaunchUi:OnDisableUi()
        self:OnDisable()
    end

    function XUiLaunchUi:OnDisable()
        CS.UnityEngine.Screen.sleepTimeout = CS.UnityEngine.SleepTimeout.SystemSetting
        self:RemoveAutoScrollTimer()
    end
    
    function XUiLaunchUi:OnClickBtnMask()
        self.BtnSkipVideo.gameObject:SetActiveEx(true)
    end

    function XUiLaunchUi:OnDestroyUi()
        self:OnDestroy()
    end
    
    function XUiLaunchUi:OnDestroy()
        self.BtnBasic.CallBack = nil
        self.BtnAll.CallBack = nil
        self.BtnConfirmSelect.CallBack = nil

        self.BtnSkipVideo.CallBack = nil
        self.BtnVideo.CallBack = nil
        if self.BtnMask then 
            self.BtnMask.CallBack = nil
        end

        self.BtnDialogConfirm.CallBack = nil
        self.BtnDialogCancel.CallBack = nil

        self.BtnLast.CallBack = nil
        self.BtnNext.CallBack = nil

        if self.DynamicTable then
            self.DynamicTable:Clear()
            self.DynamicTable = nil
        end
        self.VideoPlayerUgui.ActionEnded = nil
    end

    local function FormatSec2Min(seconds)
        local min = MathFloor(seconds / 60)
        seconds = seconds - min * 60
        
        local hour = 0
        if min >= 60 then
            hour = MathFloor(min / 60)
            min = min - hour * 60
        end
        return StringFormat("%02d:%02d:%02d", hour, min, seconds)
    end
    
    local function ConvertUnits(mbSize)
        if mbSize > 1 then
            return mbSize, "MB"
        else
            mbSize = mbSize * 1024
        end

        if mbSize > 1 then
            return mbSize, "KB"
        else
            return mbSize * 1024, "B"
        end
    end

    function XUiLaunchUi:OnGetEvents()
        return { CS.XEventId.EVENT_LAUNCH_SETMESSAGE,
        CS.XEventId.EVENT_LAUNCH_SETPROGRESS,
        CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD,
        CS.XEventId.EVENT_LAUNCH_CG,
        CS.XEventId.EVENT_LAUNCH_START_LOADING,
        CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT,
        CS.XEventId.EVENT_LAUNCH_DIALOG}
    end

    function XUiLaunchUi:OnNotify(evt, ...)
        local args = { ... }
        -- print("[LauncTest] OnNotify evt:" .. tostring(evt) .. ", args[1]:" .. tostring(args[1]))
        if evt == CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD then
            if not self.IsPlayingCG then
                self.UiDownload:SetActiveEx(true)
                self:OnRefresh()
            end

            self.UiLoading:SetActiveEx(false)
            self.UpdateSize = args[1]
            self.NeedUnit = (args[2] ~= false)
            self.MBSize = self.NeedUnit and self.UpdateSize / 1024 / 1024 or self.UpdateSize
            self.CustomFormat = args[3]

            if self.NeedUnit then
                local size, unit = ConvertUnits(self.MBSize)
                self.TxtDownloadSize.text = StringFormat("(0%s/%d%s)", unit, MathFloor(size), unit)
                self.TxtDownloadTime.gameObject:SetActiveEx(true)
            else
                self.TxtDownloadSize.text = StringFormat("(0/%d)", MathFloor(self.MBSize))
                self.TxtDownloadSpeed.text = ""
                self.TxtDownloadTime.text = ""
                self.TxtDownloadTime.gameObject:SetActiveEx(false)
            end

            --用滑动窗口来计算下载速度
            self.SizeWindow = NewQueue()
            self.TimeWindow = NewQueue()
            self.WindowTimeSum = 0
            self.WindowSizeSum = 0
            self.WindowSize = 5
            self.LastSpeed = 0

        elseif evt == CS.XEventId.EVENT_LAUNCH_CG then
            local needCGBtn = args[1]
            local needPlayCG = args[2]
            self.VideoUrl = args[3]
            self.Videowidth = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoWidth")
            self.VideoHeight = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoHeight")
            self.BtnVideo.gameObject:SetActiveEx(needCGBtn)
            if needPlayCG then
                self:CheckPlayCG()
            end
            self:CheckAutoScrollTimer()

        elseif evt == CS.XEventId.EVENT_LAUNCH_START_LOADING then
            -- stop cg
            self.UiVideoPlay:SetActiveEx(false)
            if self.IsPlayingCG then
                self.IsPlayingCG = false
                self.VideoPlayerUgui:Stop()
            end
            self.UiDownload:SetActiveEx(false)
            self.UiLoading:SetActiveEx(true)

        elseif evt == CS.XEventId.EVENT_LAUNCH_SETMESSAGE then
            if (self.UiLoading.activeInHierarchy) then
                self.TxtMessageLoading.text = tostring(args[1])
            else
                self.TxtMessageDownload.text = tostring(args[1])
            end
        elseif evt == CS.XEventId.EVENT_LAUNCH_SETPROGRESS then
            local progress = args[1]
            if (self.UiLoading.activeInHierarchy) then
                self.SliderLoading.value = progress
                self.TxtProgressLoading.text = StringFormat("%d%%", MathFloor(progress * 100))
            elseif (self.UiVideoPlay.activeInHierarchy) then
                self.TxtProgressVideoPlay.text = StringFormat("%d%%", MathFloor(progress * 100))
                self.ImageVideoProgress.fillAmount = progress
            elseif (self.UiDownload.activeInHierarchy) then
                -- 版本
                self.TxtAppVer.text = CS.XRemoteConfig.ApplicationVersion
                self.TxtDocVer.text = CS.XRemoteConfig.DocumentVersion
                -- 速度
                local deltaTime = CS.UnityEngine.Time.time - self.LastUpdateTime
                if self.NeedUnit and (deltaTime > 1) then
                    local deltaSize = MathFloor((progress - self.LastProgress) * (self.UpdateSize / 1024))
                    Enqueue(self.SizeWindow, deltaSize)
                    Enqueue(self.TimeWindow, deltaTime)
                    self.WindowSizeSum = self.WindowSizeSum + deltaSize
                    self.WindowTimeSum = self.WindowTimeSum + deltaTime
                    if Count(self.SizeWindow) > self.WindowSize then
                        self.WindowSizeSum = self.WindowSizeSum - Dequeue(self.SizeWindow)
                        self.WindowTimeSum = self.WindowTimeSum - Dequeue(self.TimeWindow)
                    end

                    local currentSpeed = 0
                    if self.WindowTimeSum ~= 0 then
                        currentSpeed = self.WindowSizeSum / self.WindowTimeSum
                    end

                    --模拟优化，速度小于零的时候，取上次大于零的速度
                    if currentSpeed < 0 then
                        currentSpeed = self.LastSpeed
                    else
                        self.LastSpeed = currentSpeed
                    end

                    if currentSpeed > 1024 then
                        if self._IsUseChannelCdn then --用了分渠道cdn在下载速度后面加个空格
                            self.TxtDownloadSpeed.text = StringFormat("%0.1f MB/S", currentSpeed / 1024)
                        else
                            self.TxtDownloadSpeed.text = StringFormat("%0.1fMB/S", currentSpeed / 1024)
                        end
                    else
                        if self._IsUseChannelCdn then
                            self.TxtDownloadSpeed.text = StringFormat("%d KB/S", MathFloor(currentSpeed))
                        else
                            self.TxtDownloadSpeed.text = StringFormat("%dKB/S", MathFloor(currentSpeed))
                        end
                    end
                    self.LastUpdateTime = CS.UnityEngine.Time.time
                    self.LastProgress = progress

                    if progress > 0 and currentSpeed > 0 then
                        local time = math.ceil(((1 - progress) * self.MBSize) / (currentSpeed / 1024))
                        self.TxtDownloadTime.text = self.DownloadCostTimeTitle .. FormatSec2Min(time) -- "预计时间："
                    elseif currentSpeed <= 0 then
                        self.TxtDownloadTime.text = self.DownloadCostTimeTitleDefault -- "预计时间：00:00:00"
                    end
                end
                self.SliderDownload.value = progress
                self:UpdateDownloadProgressEffect(progress)
                -- 进度
                self.TxtDownloadProgress.text = StringFormat("%d%%", MathFloor(progress * 100))
                if self.NeedUnit then
                    local size, unit = ConvertUnits(self.MBSize)
                    self.TxtDownloadSize.text = StringFormat(self.CustomFormat or "(%d%s/%d%s)", MathFloor(size * progress), unit, MathFloor(size), unit)
                else
                    self.TxtDownloadSize.text = StringFormat(self.CustomFormat or "(%d/%d)", MathFloor(self.MBSize * progress), MathFloor(self.MBSize))
                end
            end
        elseif evt == CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT then
            self:SetupDownloadSelect(args)
        elseif evt == CS.XEventId.EVENT_LAUNCH_DIALOG then
            self.TxtDialogInfo.text = args[1]
            self.DialogCancelCB = args[2]
            self.DialogConfirmCB = args[3]
            self.PanelDialog:SetActiveEx(true)
        end
    end

    function XUiLaunchUi:UpdateDownloadProgressEffect(progress)
        if self.DownloadProgressEffectTrans then
            self.DownloadEffectPos.x = MathFloor(self.DownloadMaxWidth * progress)
            self.DownloadProgressEffectTrans.localPosition = self.DownloadEffectPos
        end
    end

    function XUiLaunchUi:OnEffectLoaded()
        self.DownloadProgressEffectTrans = self.DownloadProgressEffect.transform
        local originPos = self.DownloadProgressEffectTrans.localPosition
        self.DownloadEffectPos = Vector3(0, originPos.y, originPos.z)
        self.DownloadMaxWidth = self.DownloadProgressEffectTrans.parent:GetComponent("RectTransform").rect.width
        self.DownloadProgressEffectTrans.localPosition = self.DownloadEffectPos
    end


    function XUiLaunchUi:OnSelectBasic()
        self.CurrentDownloadSelect = 1
        self.BtnBasic:SetButtonState(CS.UiButtonState.Select)
        if CS.XRemoteConfig.LaunchSelectType == 1 then -- 支持完整下载
            self.BtnAll:SetButtonState(CS.UiButtonState.Normal)
        end
        self.BtnReportSubType.gameObject:SetActiveEx(true)
        --  CS.XLog.Debug(" self.CurrentDownloadSelect == 1")
    end

    function XUiLaunchUi:OnSelectAllDlc()
        self.CurrentDownloadSelect = 2
        self.BtnBasic:SetButtonState(CS.UiButtonState.Normal)
        self.BtnAll:SetButtonState(CS.UiButtonState.Select)
        self.BtnReportSubType.gameObject:SetActiveEx(false)
        --  CS.XLog.Debug(" self.CurrentDownloadSelect == 2")
    end

    function XUiLaunchUi:OnConfirmSelect()
        -- CS.XLog.Debug(" self.OnConfirmSelect")
        local isFullDownload = self.CurrentDownloadSelect == 2
        self.UiDownlosdTips:SetActiveEx(false)
        CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, isFullDownload)
        
        self:DoRecordSelect(self.CurrentDownloadSelect)
    end

    function XUiLaunchUi:CheckPlayCG()
        if self.IsPlayingCG then
            print("[Audio] CG Already Playing")
            return
        end
        CS.XRecord.Record("80020", "DownloadPlayVideoAuto")
        self.IsPlayingCG = true
        self.UiVideoPlay:SetActiveEx(self.IsPlayingCG)
        self.UiDownload:SetActiveEx(not self.IsPlayingCG)
        self:PlayCG()
    end

    function XUiLaunchUi:PlayCG()
        local url = self.VideoUrl
        if not self.VideoUrl or self.VideoUrl == "null" then
            print("[Audio] Play Error url is null.")
            return
        end
        if self.Videowidth ~= 0 and self.VideoHeight ~= 0 then
            self.VideoPlayerUgui:SetAspectRatio(self.Videowidth / self.VideoHeight)
        end
        self.BtnSkipVideo.gameObject:SetActiveEx(false)
        self.VideoPlayerUgui:SetVideoUrl(url)
        self.VideoPlayerUgui:Play()
        -- print("[Audio] CG starts:" .. url .. ", width:" .. self.Videowidth .. ", height:" .. self.VideoHeight)
    end

    function XUiLaunchUi:OnVideoEnded()
        if not self.IsPlayingCG then
            return
        end
        CS.XRecord.Record("80023", "DownloadPlayVideoEnded")
        self.IsPlayingCG = false
        self.UiVideoPlay:SetActiveEx(self.IsPlayingCG)
        self.UiDownload:SetActiveEx(not self.IsPlayingCG)
    end

    -- function XUiLaunchUi:OnBtnAutoClick()
    --     if self.IsPlayingCG then
    --         self.VideoPlayerUgui:Pause()
    --     else
    --         self.VideoPlayerUgui:Resume()
    --     end
    --     self.IsPlayingCG = not self.IsPlayingCG
    -- end

    function XUiLaunchUi:OnBtnSkipVideoClick()
        if not self.IsPlayingCG then
            return
        end
        CS.XRecord.Record("80022", "DownloadSkipVideoBtn")
        self.IsPlayingCG = false
        self.UiVideoPlay:SetActiveEx(self.IsPlayingCG)
        self.UiDownload:SetActiveEx(not self.IsPlayingCG)
        self.VideoPlayerUgui:Stop()
    end

    function XUiLaunchUi:OnBtnVideoClick()
        if self.IsPlayingCG then
            print("[Audio] cg is already playing")
            return
        end
        CS.XRecord.Record("80021", "DownloadPlayVideoBtn")
        self.IsPlayingCG = true
        self.UiVideoPlay:SetActiveEx(self.IsPlayingCG)
        self.UiDownload:SetActiveEx(not self.IsPlayingCG)
        self.VideoPlayerUgui:Stop() -- 临时避免重复播放，状态停留在StopProcessing的问题
        self:PlayCG()
    end

    function XUiLaunchUi:OnBtnDialogConfirmClick()
        self.PanelDialog:SetActiveEx(false)
        if self.DialogConfirmCB then
            self.DialogConfirmCB()
        end
    end

    function XUiLaunchUi:OnBtnDialogCancelClick()
        self.PanelDialog:SetActiveEx(false)
        if self.DialogCancelCB then
            self.DialogCancelCB()
        end
    end

    local GetSizeAndUnit = function(size)
        local unit = "KB"
        local num = size / 1024
        if (num > 100) then
            unit = "MB"
            num = num / 1024
        end
        return num,unit
    end

    function XUiLaunchUi:SetupDownloadSelect(args)
        --屏蔽下载提示弹窗，直接下载基础包
        if CS.XRemoteConfig.LaunchSelectType ~= 1 then
            self.UiDownlosdTips:SetActiveEx(false)
            CS.XGameEventManager.Instance:Notify(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT, false)
            return
        end
        self.UiDownlosdTips:SetActiveEx(true)
        local baseUpdateSize = args[1]
        local allUpdateSize = args[2]
        
        if self.CurrentDownloadSelect == 1 then
            self:OnSelectBasic()
        else
            self:OnSelectAllDlc()
        end

        local baseSize, baseUnit = GetSizeAndUnit(baseUpdateSize)
        local allSize, allUnit = GetSizeAndUnit(allUpdateSize)


        local descBase = StringFormat("<b>%0.2f%s</b>", baseSize, baseUnit)
        self.BtnBasic:SetNameByGroup(1, CS.XApplication.GetText("DownloadDescBase"))--"包含前三章主线与当前版本所有活动玩法资源")
        self.BtnBasic:SetNameByGroup(2, descBase)

        local descAll = StringFormat("<b>%0.2f%s</b>", allSize, allUnit)
        self.BtnAll:SetNameByGroup(1, CS.XApplication.GetText("DownloadDescAll"))--"下载完成后可体验所有内容")
        self.BtnAll:SetNameByGroup(2, descAll)

        local isSelect = XLaunchDlcManager.IsSelectWifiAutoDownload()
        if self.BtnReportSubType then
            self.BtnReportSubType:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
            self.BtnReportSubType.CallBack = function()
                self:OnBtnWifiClick()
            end
        end
    end

    function XUiLaunchUi:Ctor(name, uiProxy)
        self.Name = name
        self.UiProxy = uiProxy
        self.Ui = uiProxy.Ui
    end

    function XUiLaunchUi:SetGameObject()
        self.Transform = self.Ui.Transform
        self.GameObject = self.Ui.GameObject
        self.UiAnimation = self.Ui.UiAnimation
        self:InitUiObjects()
    end

    --用于释放lua的内存
    function XUiLaunchUi:OnReleaseUi()
        self:OnRelease()
        --self.Name = nil
        self.UiProxy = nil
        self.Ui = nil

        self.Transform = nil
        self.GameObject = nil
        self.UiAnimation = nil

        if self.Obj and self.Obj:Exist() then
            local nameList = self.Obj.NameList
            for _, v in pairs(nameList) do
                self[v] = nil
            end
            self.Obj = nil
        end

        for k, v in pairs(self) do
            local t = type(v)
            if t == 'userdata' and CS.XUiHelper.IsUnityObject(v) then
                self[k] = nil
            end
        end

    end

    function XUiLaunchUi:OnRelease()
    end

    function XUiLaunchUi:SetUiSprite(image, spriteName, callBack)
        self.UiProxy:SetUiSprite(image, spriteName, callBack)
    end

    --快捷隐藏界面（不建议使用）
    function XUiLaunchUi:SetActive(active)
        local temp = active and true or false
        self.UiProxy:SetActive(temp)
    end

    --快捷关闭界面
    function XUiLaunchUi:Close()

        if self.UiProxy == nil then
            XLog.Error(self.Name .. "重复Close")
        else
            self.UiProxy:Close()
        end

    end

    --快捷移除UI,移除的UI不会播放进场、退场动画
    function XUiLaunchUi:Remove()
        if self.UiProxy then
            self.UiProxy:Remove()
        end
    end

    --注册点击事件
    --function XUiLaunchUi:RegisterClickEvent(button, handle, clear)
    --
    --    clear = clear and true or false
    --    self.UiProxy:RegisterClickEvent(button, function(eventData)
    --        if handle then
    --            handle(self, eventData)
    --        end
    --    end, clear)
    --
    --end
    --返回指定名字的子节点的Component
    --@name 子节点名称
    --@type Component类型
    function XUiLaunchUi:FindComponent(name, type)
        return self.UiProxy:FindComponent(name, type)
    end


    --通过名字查找GameObject 例如:A/B/C
    --@name 要查找的名字
    function XUiLaunchUi:FindGameObject(name)
        return self.UiProxy:FindGameObject(name)
    end

    --通过名字查找Transfrom 例如:A/B/C
    --@name 要查找的名字
    function XUiLaunchUi:FindTransform(name)
        return self.UiProxy:FindTransform(name)
    end

    --打开一个子UI
    --@childUIName 子UI名字
    --@... 传到OnStart的参数
    function XUiLaunchUi:OpenChildUi(childUIName, ...)
        self.UiProxy:OpenChildUi(childUIName, ...)
    end

    --打开一个子UI,会关闭其他已显示的子UI
    --@childUIName 子UI名字
    --@... 传到OnStart的参数
    function XUiLaunchUi:OpenOneChildUi(childUIName, ...)
        self.UiProxy:OpenOneChildUi(childUIName, ...)
    end

    --关闭子UI
    --@childUIName 子UI名字
    function XUiLaunchUi:CloseChildUi(childUIName)
        self.UiProxy:CloseChildUi(childUIName)
    end

    --查找子窗口对应的lua对象
    --@childUiName 子窗口名字
    function XUiLaunchUi:FindChildUiObj(childUiName)
        local childUi = self.UiProxy:FindChildUi(childUiName)
        if childUi then
            return childUi.UiProxy.UiLuaTable
        end
    end

    function XUiLaunchUi:InitChildUis()
        if self.Ui == nil then
            return
        end

        if not self.Ui.UiData.HasChildUi then
            return
        end

        local childUis = self.Ui:GetAllChildUis()

        if childUis == nil then
            return
        end

        --子UI初始化完成后可在父UI通过【self.Child+子UI】名称的方式直接获取句柄
        local childUiName
        for k, v in pairs(childUis) do
            childUiName = "Child" .. k
            if self[childUiName] then
                XLog.Error(StringFormat("%s该名字已被占用", childUiName))
            else
                self[childUiName] = v.UiProxy.UiLuaTable
            end
        end
    end

    function XUiLaunchUi:InitUiObjects()
        self.Obj = self.Transform:GetComponent("UiObject")
        if self.Obj ~= nil and self.Obj:Exist() then
            for i = 0, self.Obj.NameList.Count - 1 do
                self[self.Obj.NameList[i]] = self.Obj.ObjList[i]
            end
        end
    end

    --播放动画（只支持Timeline模式）
    function XUiLaunchUi:PlayAnimation(animName, callback, beginCallback)
        self.UiProxy:PlayAnimation(animName, callback, beginCallback)
    end

    --播放动画（只支持Timeline模式, 增加Mask阻止操作打断动画）
    function XUiLaunchUi:PlayAnimationWithMask(animName, callback)
        self.UiProxy:PlayAnimation(animName, function()
            CS.XUiManager.Instance:SetMask(false)
            if callback then
                callback()
            end
        end, function()
            CS.XUiManager.Instance:SetMask(true)
        end)
    end

    function XUiLaunchUi:OnBtnWifiClick()
        local isSelect = self.BtnReportSubType:GetToggleState()
        XLaunchDlcManager.SetSelectWifiAutoDownloadValue(isSelect)
    end
    
    function XUiLaunchUi:DoRecordSelect(select)
        local dict = {}
        dict["document_version"] = CS.XRemoteConfig.DocumentVersion
        dict["app_version"] = CS.XRemoteConfig.ApplicationVersion
        -- 1:基础资源 2:全量资源
        dict["select_type"] = select
        dict["auto_wifi"] = tostring(XLaunchDlcManager.IsSelectWifiAutoDownload())
        
        CS.XRecord.Record(dict, "80032", "SubpackageSelect")
    end
    
    return XUiLaunchUi
end

return Creator