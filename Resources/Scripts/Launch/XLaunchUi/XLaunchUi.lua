local Creator = function()
    local XUiLaunchUi = {}

    function XUiLaunchUi:OnAwake()
        --self.TxtProgressLoading.gameObject:SetActiveEx(true)
        --CS.XLog.Error("new ui lua.")
        self.UiLoading = self.UiLoading.gameObject
        self.UiDownload = self.UiDownload.gameObject
        self.UiVideoPlay = self.UiVideoPlay.gameObject
        self.UiDownlosdTips = self.UiDownlosdTips.gameObject

        self.UiLoading:SetActiveEx(false)
        self.UiDownload:SetActiveEx(false)
        self.UiVideoPlay:SetActiveEx(false)
        self.UiDownlosdTips:SetActiveEx(false)

        --self.BtnSkipVideo.CallBack = delegate(int i) {  }
        self.BtnMusicOn.CallBack = function()
            self.BtnMusicOn.gameObject:SetActiveEx(false)
            self.BtnMusicOff.gameObject:SetActiveEx(true)
        end
        self.BtnMusicOff.CallBack = function()
            self.BtnMusicOn.gameObject:SetActiveEx(true)
            self.BtnMusicOff.gameObject:SetActiveEx(false)
        end

        self.BtnBasic.CallBack = function() self:OnSelectBasic() end
        self.BtnAll.CallBack = function() self:OnSelectAllDlc() end
        self.BtnConfirmSelect.CallBack = function() self:OnConfirmSelect() end
        

        --self.BtnVideo.CallBack = delegate (int i) { }
        self.UpdateSize = 0
        self.MBSize = 0
        self.LastUpdateTime = 0
        self.LastProgress = 0

        self.CurrentDownloadSelect = 1
    end

    function XUiLaunchUi:OnStart()
        self:HideHealthTip()
    end

    function XUiLaunchUi:HideHealthTip()
        if self.UiLoading then -- 海外屏蔽健康提示十六字真言(不想改UI免得还得修改)
            for i = 1, self.UiLoading.transform.childCount do
                local child = self.UiLoading.transform:GetChild(i-1)
                if child.name == "Text" then
                    child.gameObject:SetActiveEx(false)
                end
            end
        end
    end

    function XUiLaunchUi:OnEnable()
        CS.UnityEngine.Screen.sleepTimeout = CS.UnityEngine.SleepTimeout.NeverSleep
    end

    function XUiLaunchUi:OnDisable()
        CS.UnityEngine.Screen.sleepTimeout = CS.UnityEngine.SleepTimeout.SystemSetting
    end

    function XUiLaunchUi:OnDestroy()
        self.BtnMusicOn.CallBack = nil
        self.BtnMusicOff.CallBack = nil

        self.BtnBasic.CallBack = nil
        self.BtnAll.CallBack = nil
        self.BtnConfirmSelect.CallBack = nil
    end

    function XUiLaunchUi:OnGetEvents()
        return { CS.XEventId.EVENT_LAUNCH_SETMESSAGE,
        CS.XEventId.EVENT_LAUNCH_SETPROGRESS,
        CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD,
        CS.XEventId.EVENT_LAUNCH_START_LOADING,
        CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT}
    end

    function XUiLaunchUi:OnNotify(evt, ...)
        local args = { ... }
        if evt == CS.XEventId.EVENT_LAUNCH_START_DOWNLOAD then
            self.UiDownload:SetActiveEx(true)
            self.UiLoading:SetActiveEx(false)
            self.UpdateSize = args[1]
            self.MBSize = self.UpdateSize / 1024 / 1024
            self.TxtDownloadSize.text = string.format("(0MB/%dMB)", math.floor(self.MBSize))
        elseif evt == CS.XEventId.EVENT_LAUNCH_START_LOADING then
            self.UiDownload:SetActiveEx(false)
            self.UiLoading:SetActiveEx(true)
        elseif evt == CS.XEventId.EVENT_LAUNCH_SETMESSAGE then
            self.TxtMessageLoading.text = tostring(args[1])
        elseif evt == CS.XEventId.EVENT_LAUNCH_SETPROGRESS then
            self.VideoPlayer.targetCamera = CS.XUiManager.Instance.UiCamera
            local progress = args[1]
            if (self.UiLoading.activeInHierarchy) then
                self.SliderLoading.value = progress
                self.TxtProgressLoading.text = string.format("%d%%", math.floor(progress * 100))
            elseif (self.UiDownload.activeInHierarchy) then
                if (self.TxtAppVer ~= nil and self.TxtAppVer:Exist()) then
                    self.TxtAppVer.text = CS.XRemoteConfig.ApplicationVersion .. " (ApplicationVersion)"
                end

                if (self.TxtDocVer ~= nil and self.TxtDocVer:Exist()) then
                    self.TxtDocVer.text = CS.XRemoteConfig.DocumentVersion .. " (DocumentVersion)"
                end
                if (CS.UnityEngine.Time.time - self.LastUpdateTime > 1) then
                    local kBSpeed = (progress - self.LastProgress) * (self.UpdateSize / 1024)
                    self.TxtDownloadSpeed.text = string.format("%dKB/S", math.floor(kBSpeed))
                    self.LastUpdateTime = CS.UnityEngine.Time.time
                    self.LastProgress = progress
                end

                self.SliderDownload.value = progress
                self.TxtProgressDownload.text = string.format("%d%%", math.floor(progress * 100))
                self.TxtDownloadSize.text = string.format("(%dMB/%dMB)", math.floor(self.MBSize * progress), math.floor(self.MBSize))
            elseif (self.UiVideoPlay.activeInHierarchy) then
                self.TxtProgressVideoPlay.text = string.format("%d%%", math.floor(progress * 100))
            end
        elseif evt == CS.XEventId.EVENT_LAUNCH_SHOW_DOWNLOAD_SELECT then
            self:SetupDownloadSelect(args)
        end
    end

    function XUiLaunchUi:OnSelectBasic()
        self.CurrentDownloadSelect = 1
        self.BtnBasic:SetButtonState(CS.UiButtonState.Select)
        self.BtnAll:SetButtonState(CS.UiButtonState.Normal)
    end

    function XUiLaunchUi:OnSelectAllDlc()
        self.CurrentDownloadSelect = 2
        self.BtnBasic:SetButtonState(CS.UiButtonState.Normal)
        self.BtnAll:SetButtonState(CS.UiButtonState.Select)
    end

    function XUiLaunchUi:OnConfirmSelect()
        self.UiDownlosdTips:SetActiveEx(false)
        CsGameEventManager:Notify(CS.XEventId.EVENT_LAUNCH_DONE_DOWNLOAD_SELECT,self.CurrentDownloadSelect==2)
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
        self.UiDownlosdTips:SetActiveEx(true)
        local baseUpdateSize = args[1]
        local allUpdateSize = args[2]

        if self.CurrentDownloadSelect == 1 then
            self:OnSelectBasic()
        else
            self:OnSelectAllDlc()
        end

        local baseSize,baseUnit = GetSizeAndUnit(baseUpdateSize)
        local allSize,allUnit = GetSizeAndUnit(allUpdateSize)

        self.BtnBasic:SetNameByGroup(1,string.format("<b>%d%s</b>", baseSize,baseUnit))

        self.BtnAll:SetNameByGroup(1,string.format("<b>%d%s</b>", allSize,allUnit))

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
    function XUiLaunchUi:OnRelease()

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
            if t == 'userdata' and CsXUiHelper.IsUnityObject(v) then
                self[k] = nil
            end
        end

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
                XLog.Error(string.format("%s该名字已被占用", childUiName))
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

    return XUiLaunchUi
end

return Creator