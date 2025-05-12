local CrashState = {
    None = 0,
    Normal = 1,
    Crash = 2,
}

---@class XUiPanelTheatre4BaseGrid : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4BaseGrid = XClass(XUiNode, "XUiPanelTheatre4BaseGrid")

function XUiPanelTheatre4BaseGrid:Ctor()
    self.MapId = 0
    ---@type XTheatre4Grid
    self.GridData = nil
    self.BlockIconId = {
        [XEnumConst.Theatre4.GridType.Start] = 1,
        [XEnumConst.Theatre4.GridType.Hurdle] = 10,
    }
    self.BlockIconIdFunc = {
        [XEnumConst.Theatre4.GridType.Shop] = self._Control.GetShopBlockIcon,
        [XEnumConst.Theatre4.GridType.Box] = self._Control.GetBoxGroupBlockIcon,
        [XEnumConst.Theatre4.GridType.Monster] = self._Control.GetFightBlockIcon,
        [XEnumConst.Theatre4.GridType.Boss] = self._Control.GetFightBlockIcon,
        [XEnumConst.Theatre4.GridType.Event] = self._Control.GetEventBlockIcon,
    }
    self.GridNameKeys = {
        [XEnumConst.Theatre4.GridType.Empty] = "EmptyGridProcessedName",
        [XEnumConst.Theatre4.GridType.Hurdle] = "HurdleGridName",
    }
    self.GridNameFunc = {
        [XEnumConst.Theatre4.GridType.Shop] = self._Control.GetShopName,
        [XEnumConst.Theatre4.GridType.Box] = self._Control.GetBoxGroupName,
        [XEnumConst.Theatre4.GridType.Monster] = self._Control.GetFightName,
        [XEnumConst.Theatre4.GridType.Event] = self._Control.GetEventName,
        [XEnumConst.Theatre4.GridType.Building] = self._Control.GetBuildingName,
    }
    -- 上一个探索步骤
    self.LastGridExploreStep = XEnumConst.Theatre4.GridExploreStep.None
    -- 当前探索步骤
    self.CurGridExploreStep = XEnumConst.Theatre4.GridExploreStep.None
    self:InitCommonUi()
    -- 按钮点击回调
    self.BtnClickCallback = false
    if self.BtnClick then
        self._Control:RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    end
    -- 当前是第几层
    self.CurrentFloor = 0
    -- 层级动画
    ---@type table<number, UnityEngine.Playables.PlayableDirector>
    self.FloorAnim = {
        [1] = self.MapGridDisable:GetComponent("PlayableDirector"),
        [2] = self.MapGridEnable:GetComponent("PlayableDirector"),
    }
    -- 当前格子探索状态
    self.CurGridExploreState = -1
    -- 当前格子动画是否被打断
    self.CurGridAnimIsInterrupted = false
    
    self._CrashState = CrashState.None
end

-- 添加点击回调
function XUiPanelTheatre4BaseGrid:RegisterClick(callback)
    self.BtnClickCallback = callback
end

-- 按钮点击
function XUiPanelTheatre4BaseGrid:OnBtnClick()
    if XEnumConst.Theatre4.IsDebug then
        self:PrintGridInfo()
    end
    -- 查看地图中
    if self._Control:CheckIsViewMap() then
        return
    end
    -- 历史章节不可点击
    if not self._Control.MapSubControl:CheckHistoryChapterCanClick(self.MapId) then
        return
    end
    -- 建造中
    if self:IsBuilding() then
        self:OnBuildingClick()
        return
    end
    -- 未知状态
    if self.GridData:IsGridStateUnknown() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ExploreUnknownTip"))
        return
    end
    if self.BtnClickCallback then
        self.BtnClickCallback()
    end
end

--region 探索格子相关

---@param gridData XTheatre4Grid
function XUiPanelTheatre4BaseGrid:SetGridData(mapId, gridData, floor)
    self.MapId = mapId
    self.GridData = gridData
    self.CurrentFloor = floor
end

-- 刷新接口需要子类重写
function XUiPanelTheatre4BaseGrid:Refresh()
    self:RefreshDisableCountDown()
end

-- 打印格子信息
function XUiPanelTheatre4BaseGrid:PrintGridInfo()
    local posX, posY = self.GridData:GetGridPos()
    XLog.Warning("<color=#F1D116>Theatre4:</color> 地图Id:" .. self.MapId ..
            " 格子类型:" .. self.GridData:GetGridType() ..
            " X:" .. posX ..
            " Y:" .. posY ..
            " 状态:" .. self.GridData:GetGridState() ..
            " 格子配置Id:" .. self.GridData.GridId ..
            " 内容组:" .. self.GridData:GetGridContentGroup() ..
            " 内容Id:" .. self.GridData:GetGridContentId())
end

-- 初始化Ui
function XUiPanelTheatre4BaseGrid:InitCommonUi()
    if self.PanelUnknown then
        self.PanelUnknown.gameObject:SetActiveEx(false)
    end
    if self.PanelVisible then
        self.PanelVisible.gameObject:SetActiveEx(false)
    end
    if self.PanelDiscover then
        self.PanelDiscover.gameObject:SetActiveEx(false)
    end
    if self.PanelExplored then
        self.PanelExplored.gameObject:SetActiveEx(false)
    end
    if self.PanelProcessed then
        self.PanelProcessed.gameObject:SetActiveEx(false)
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
    if self.ImgEnemy then
        self.ImgEnemy.gameObject:SetActiveEx(false)
    end
end

-- 刷新格子颜色
function XUiPanelTheatre4BaseGrid:RefreshColor(panelUi)
    if not panelUi then
        return
    end
    if not panelUi.ImgTypeRed then
        return
    end
    panelUi.ImgTypeRed.gameObject:SetActiveEx(self.GridData:IsGridColorRed())
    panelUi.ImgTypeYellow.gameObject:SetActiveEx(self.GridData:IsGridColorYellow())
    panelUi.ImgTypeBlue.gameObject:SetActiveEx(self.GridData:IsGridColorBlue())
end

-- 刷新格子背景颜色
function XUiPanelTheatre4BaseGrid:RefreshBgColor(panelUi)
    if not panelUi then
        return
    end
    local bgIcon = self:GetGridBgColorIcon()
    if not bgIcon then
        return
    end
    if panelUi.RmgBg then
        panelUi.RmgBg:SetRawImage(bgIcon)
    end
end

-- 刷新格子图片
function XUiPanelTheatre4BaseGrid:RefreshIcon(panelUi, isColorIcon)
    if not panelUi then
        return
    end
    local icon = isColorIcon and self:GetGridColorIcon() or self:GetGridIcon()
    if not icon then
        return
    end
    if panelUi.RImgTypeIcon then
        panelUi.RImgTypeIcon:SetRawImage(icon)
    end
end

-- 刷新格子名称
function XUiPanelTheatre4BaseGrid:RefreshName(panelUi)
    if not panelUi then
        return
    end
    if panelUi.TxtName then
        -- 如果已坠毁，但未完成，则不显示名称
        if self:IsHasBeenCrush() then
            if not self.GridData:IsGridStateProcessed() then
                panelUi.TxtName.text = ""
                return
            end
        end
        panelUi.TxtName.text = self:GetGridName()
    end
end

-- 刷新未知状态
function XUiPanelTheatre4BaseGrid:RefreshUnknown()
    local isUnknown = self.GridData:IsGridStateUnknown()
    self.PanelUnknown.gameObject:SetActiveEx(isUnknown)
    if not isUnknown then
        return
    end
    if not self.PanelUnknownUi then
        self.PanelUnknownUi = {}
        XTool.InitUiObjectByInstance(self.PanelUnknown, self.PanelUnknownUi)
    end
    self:RefreshColor(self.PanelUnknownUi)
end

-- 刷新可见状态
function XUiPanelTheatre4BaseGrid:RefreshVisible()
    local isVisible = self.GridData:IsGridStateVisible()
    if self._CrashState == CrashState.Crash then
        isVisible = false
    end
    self.PanelVisible.gameObject:SetActiveEx(isVisible)
    if not isVisible then
        return
    end
    if not self.PanelVisibleUi then
        self.PanelVisibleUi = {}
        XTool.InitUiObjectByInstance(self.PanelVisible, self.PanelVisibleUi)
    end
    self:RefreshIcon(self.PanelVisibleUi)
    self:RefreshColor(self.PanelVisibleUi)
end

-- 刷新发现状态
function XUiPanelTheatre4BaseGrid:RefreshDiscover()
    local isDiscover = self.GridData:IsGridStateDiscover()
    self.PanelDiscover.gameObject:SetActiveEx(isDiscover)
    if not isDiscover then
        return
    end
    if not self.PanelDiscoverUi then
        self.PanelDiscoverUi = {}
        XTool.InitUiObjectByInstance(self.PanelDiscover, self.PanelDiscoverUi)
    end
    self:RefreshIcon(self.PanelDiscoverUi, true)
    self:RefreshBgColor(self.PanelDiscoverUi)
    self:RefreshColor(self.PanelDiscoverUi)
    self:RefreshName(self.PanelDiscoverUi)
end

-- 刷新探索状态
function XUiPanelTheatre4BaseGrid:RefreshExplored()
    local isExplored = self.GridData:IsGridStateExplored()
    if self.GridData:IsHasBeenCrush() then
        isExplored = false
    end
    self.PanelExplored.gameObject:SetActiveEx(isExplored)
    if not isExplored then
        return
    end
    if not self.PanelExploredUi then
        self.PanelExploredUi = {}
        XTool.InitUiObjectByInstance(self.PanelExplored, self.PanelExploredUi)
    end
    self:RefreshIcon(self.PanelExploredUi)
    self:RefreshName(self.PanelExploredUi)
end

-- 刷新已处理状态
function XUiPanelTheatre4BaseGrid:RefreshProcessed()
    local isProcessed = self.GridData:IsGridStateProcessed()
    self.PanelProcessed.gameObject:SetActiveEx(isProcessed)
    if not isProcessed then
        return
    end
    if not self.PanelProcessedUi then
        self.PanelProcessedUi = {}
        XTool.InitUiObjectByInstance(self.PanelProcessed, self.PanelProcessedUi)
    end
    self:RefreshIcon(self.PanelProcessedUi)
    self:RefreshName(self.PanelProcessedUi)
end

-- 是否选择
function XUiPanelTheatre4BaseGrid:SetSelected(isSelected)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelected)
    end
end

-- 获取块图标Id
function XUiPanelTheatre4BaseGrid:GetBlockIconId()
    local gridType = self.GridData:GetGridType()
    if self.BlockIconId[gridType] then
        return self.BlockIconId[gridType]
    end
    local displayId = self.GridData:GetGridDisplayId()
    if not XTool.IsNumberValid(displayId) then
        return 0
    end
    if self.BlockIconIdFunc[gridType] then
        return self.BlockIconIdFunc[gridType](self._Control, displayId)
    end
    return 0
end

-- 获取格子图标
function XUiPanelTheatre4BaseGrid:GetGridIcon()
    -- 建筑格子
    if self.GridData:IsGridTypeBuilding() then
        return self._Control:GetBuildingIcon(self.GridData:GetGridBuildingId())
    end
    local blockIconId = self:GetBlockIconId()
    if blockIconId > 0 then
        return self._Control:GetBlockIconDefaultIcon(blockIconId)
    end
    return nil
end

-- 获取格子颜色图标
function XUiPanelTheatre4BaseGrid:GetGridColorIcon()
    local blockIconId = self:GetBlockIconId()
    if blockIconId > 0 then
        local colorIcons = self._Control:GetBlockIconColorIcon(blockIconId)
        local colorId = self.GridData:GetGridColor()
        return colorIcons and colorIcons[colorId] or nil
    end
    return nil
end

-- 获取格子背景颜色图标
function XUiPanelTheatre4BaseGrid:GetGridBgColorIcon()
    local colorId = self.GridData:GetGridColor()
    local colorBgIcon = self._Control:GetClientConfig("DiscoverGridColorBg", colorId)
    return colorBgIcon or nil
end

-- 获取格子名称
function XUiPanelTheatre4BaseGrid:GetGridName()
    local gridType = self.GridData:GetGridType()
    if self.GridNameKeys[gridType] then
        return self._Control:GetClientConfig(self.GridNameKeys[gridType])
    end
    if self.GridNameFunc[gridType] then
        local displayId = self.GridData:GetGridDisplayId()
        if not XTool.IsNumberValid(displayId) then
            return ""
        end
        return self.GridNameFunc[gridType](self._Control, displayId)
    end
    return ""
end

-- 获取格子探索步骤
function XUiPanelTheatre4BaseGrid:GetGridExploreStep()
    -- 可见状态 或 可探索状态
    if self.GridData:IsGridStateVisible() or self.GridData:IsGridStateDiscover() then
        return XEnumConst.Theatre4.GridExploreStep.Explore
    end
    -- 已探索状态
    if self.GridData:IsGridStateExplored() then
        local eventId = self.GridData:GetGridEventId()
        if XTool.IsNumberValid(eventId) then
            return XEnumConst.Theatre4.GridExploreStep.Event
        end
        if self.GridData:IsGridTypeMonster() or self.GridData:IsGridTypeBoss() then
            if self.LastGridExploreStep ~= XEnumConst.Theatre4.GridExploreStep.Explore then
                return XEnumConst.Theatre4.GridExploreStep.Explore
            end
            return XEnumConst.Theatre4.GridExploreStep.Battle
        end
    end
    -- 已处理状态
    if self.GridData:IsGridStateProcessed() then
        if self.GridData:IsGridTypeShop() then
            return XEnumConst.Theatre4.GridExploreStep.Shop
        end
    end
    if self.LastGridExploreStep ~= XEnumConst.Theatre4.GridExploreStep.None then
        return XEnumConst.Theatre4.GridExploreStep.End
    end
    return XEnumConst.Theatre4.GridExploreStep.None
end

-- 执行探索步骤
function XUiPanelTheatre4BaseGrid:DoGridExploreStep()
    -- 已坠毁
    if self:IsHasBeenCrush() then
        return
    end
    
    self.LastGridExploreStep = self.CurGridExploreStep
    self.CurGridExploreStep = self:GetGridExploreStep()
    if XEnumConst.Theatre4.IsDebug then
        XLog.Debug("<color=#F1D116>Theatre4:</color> 上一个探索步骤:" .. self.LastGridExploreStep ..
                " 当前探索步骤:" .. self.CurGridExploreStep ..
                " 格子类型:" .. self.GridData:GetGridType() ..
                " 格子状态:" .. self.GridData:GetGridState())
    end
    if self.LastGridExploreStep == self.CurGridExploreStep then
        return
    end
    if self.CurGridExploreStep == XEnumConst.Theatre4.GridExploreStep.Explore then
        self:OpenGridDetail()
    elseif self.CurGridExploreStep == XEnumConst.Theatre4.GridExploreStep.Event then
        self:OpenGridEvent()
    elseif self.CurGridExploreStep == XEnumConst.Theatre4.GridExploreStep.Battle then
        self:OpenBattle()
    elseif self.CurGridExploreStep == XEnumConst.Theatre4.GridExploreStep.Shop then
        self:OpenShop()
    elseif self.CurGridExploreStep == XEnumConst.Theatre4.GridExploreStep.End then
        -- boss 完成后格子类型不会改变
        if self.GridData:IsGridTypeBoss() and self.GridData:IsGridStateProcessed() then
            if XMVCA.XTheatre4:CheckAndOpenAdventureSettle() then
                return
            end
        end
        -- 结束时检查是否需要弹窗
        self._Control:CheckNeedOpenNextPopup()
    end
end

-- 打开格子详情
function XUiPanelTheatre4BaseGrid:OpenGridDetail()
    self:SetSelected(true)
    XLuaUiManager.Open("UiTheatre4Outpost", self.MapId, self.GridData, function()
        self:DoGridExploreStep()
    end, function()
        self:SetSelected(false)
    end)
end

-- 打开格子事件
function XUiPanelTheatre4BaseGrid:OpenGridEvent()
    self:SetSelected(true)
    local eventId = self.GridData:GetGridEventId()
    self._Control:OpenEventUi(eventId, self.MapId, self.GridData, nil,function()
        self:DoGridExploreStep()
    end, function()
        self:SetSelected(false)
    end)
end

-- 打开商店
function XUiPanelTheatre4BaseGrid:OpenShop()
    self:SetSelected(true)
    XLuaUiManager.Open("UiTheatre4Shop", self.MapId, self.GridData, function()
        self:SetSelected(false)
    end)
end

-- 打开战斗
function XUiPanelTheatre4BaseGrid:OpenBattle()
    local stageId = self.GridData:GetGridFightStageId()
    local posX, posY = self.GridData:GetGridPos()
    self._Control:OpenBattlePanel(stageId, self.MapId, posX, posY)
end

--endregion

--region 建造格子相关

-- 是否是正在建造
function XUiPanelTheatre4BaseGrid:IsBuilding()
    return self._Control.MapSubControl:CheckIsBuilding()
end

-- 正在建造点击事件
function XUiPanelTheatre4BaseGrid:OnBuildingClick()
    local mapBuildData = self._Control.MapSubControl:GetMapBuildData()
    local isBuildCondition = self._Control.MapSubControl:CheckActiveSkillCondition(mapBuildData:GetEffectType(), self.GridData, true)
    if not isBuildCondition then
        return
    end
    if mapBuildData:GetMapId() == self.MapId and mapBuildData:GetGridId() == self.GridData:GetGridId() then
        return
    end
    local posX, posY = self.GridData:GetGridPos()
    local gridId = self.GridData:GetGridId()
    self._Control.MapSubControl:SetMapBuildGridData(self.MapId, gridId, posX, posY)
end

--endregion

--region 相机拖拽缩放相关

-- 获取当前格子的世界坐标
---@return number, number X坐标, Y坐标
function XUiPanelTheatre4BaseGrid:GetGridWorldPos()
    local position = self.Transform.position
    return position.x, position.y
end

-- 获取聚焦格子的偏移值
---@return number, number 偏移X, 偏移Y
function XUiPanelTheatre4BaseGrid:GetFocusGridOffset()
    local offsetX = self._Control:GetClientConfig("ClickGridLensFocusOffset", 1, true)
    local offsetY = self._Control:GetClientConfig("ClickGridLensFocusOffset", 2, true)
    return offsetX, offsetY
end

-- 获取格子的聚焦时间
---@return number 聚焦时间
function XUiPanelTheatre4BaseGrid:GetFocusGridTime()
    return self._Control:GetClientConfig("ClickGridLensFocusTime", 1, true) / 1000
end

-- 聚焦到格子
---@param x number X世界坐标
---@param y number Y世界坐标
---@param duration number 聚焦时间
---@param ease DG.Tweening.Ease 缓动类型
---@param callback function 聚焦完成回调
function XUiPanelTheatre4BaseGrid:FocusToGrid(x, y, duration, ease, callback)
    self._Control.MapSubControl:FocusCameraToPosition(x, y, duration, ease, callback)
end

-- 聚焦到格子
---@param callback function 聚焦完成回调
function XUiPanelTheatre4BaseGrid:InternalFocusToGrid(callback)
    -- 聚焦前先缓存相机位置
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_SAVE_CAMERA_POS)
    local x, y = self:GetGridWorldPos()
    local offsetX, offsetY = self:GetFocusGridOffset()
    local duration = self:GetFocusGridTime()
    self:FocusToGrid(x + offsetX, y + offsetY, duration, nil, callback)
end

--endregion

--region 动画和特效

-- 处理层级动画
function XUiPanelTheatre4BaseGrid:HandleFloorAnim(lastFloor, curFloor, isLastFrame)
    if curFloor == 1 then
        self:HideGridEffect()
    end
    if lastFloor > 0 then
        local lastAnim = self.FloorAnim[lastFloor]
        if lastAnim then
            lastAnim:Stop()
            lastAnim:Evaluate()
        end
    end
    local curAnim = self.FloorAnim[curFloor]
    if curAnim then
        curAnim.time = isLastFrame and curAnim.duration - 0.001 or 0
        curAnim:Play()
        curAnim:Evaluate()
    end
end

-- 设置层级
function XUiPanelTheatre4BaseGrid:SetFloor(floor)
    self.CurrentFloor = floor
end

-- 播放被打断的格子动画
function XUiPanelTheatre4BaseGrid:PlayInterruptGridAnim()
    if self.CurGridAnimIsInterrupted then
        self.CurGridAnimIsInterrupted = false
        local animName = self:GetGridAnimName()
        self:PlayGridAnimation(animName)
    end
end

-- 获取格子动画名
function XUiPanelTheatre4BaseGrid:GetGridAnimName()
    return "PanelCommonEnable"
end

-- 播放格子动画 保存动画打断状态
---@param animName string 动画名
function XUiPanelTheatre4BaseGrid:PlayGridAnimation(animName)
    self:PlayAnimation(animName, function(isFinish)
        if not isFinish and not XLuaUiManager.IsUiShow("UiTheatre4Game") then
            -- 动画未播放完且界面隐藏
            if XEnumConst.Theatre4.IsDebug then
                XLog.Warning("<color=#F1D116>Theatre4:</color> 格子动画被打断")
            end
            self.CurGridAnimIsInterrupted = true
        end
    end)
end

-- 播放格子动画
function XUiPanelTheatre4BaseGrid:PlayGridAnim()
    -- 状态未改变不播放动画
    if self.CurGridExploreState == self.GridData:GetGridState() then
        return
    end
    self.CurGridExploreState = self.GridData:GetGridState()
    -- 1层不播放动画
    if self.CurrentFloor <= 1 then
        return
    end
    local animName = self:GetGridAnimName()
    self:PlayGridAnimation(animName)
end

-- 播放格子特效
function XUiPanelTheatre4BaseGrid:PlayGridEffect()
end

-- 隐藏格子特效
function XUiPanelTheatre4BaseGrid:HideGridEffect()
end

-- 显示建造特效
function XUiPanelTheatre4BaseGrid:ShowBuildingEffect(selectGridId)
    if selectGridId == self.GridData:GetGridId() then
        self.OneselfRange.gameObject:SetActiveEx(false)
        self.OneselfRange.gameObject:SetActiveEx(true)
    else
        self.Range.gameObject:SetActiveEx(false)
        self.Range.gameObject:SetActiveEx(true)
    end
end

-- 隐藏建造特效
function XUiPanelTheatre4BaseGrid:HideBuildingEffect()
    if self.Range then
        self.Range.gameObject:SetActiveEx(false)
    end
    if self.OneselfRange then
        self.OneselfRange.gameObject:SetActiveEx(false)
    end
end

--endregion

function XUiPanelTheatre4BaseGrid:IsHasBeenCrush()
    return self.GridData:IsHasBeenCrush()
end

function XUiPanelTheatre4BaseGrid:RefreshDisableCountDown()
    if self.GridData:IsGridStateProcessed() then
        if self.PanelCrash then
            self.PanelCrash.gameObject:SetActiveEx(false)
        end
        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(false)
        end
        --self:StopAnimation("PanelCrashEnable")
        return
    end
    if self.GridData then
        local disabledDay = self.GridData:GetDisabledDay()
        if disabledDay and disabledDay > 0 then
            local currentDay = self._Control:GetDays()
            if currentDay <= disabledDay then
                self._CrashState = CrashState.Normal
                if self.PanelCrash then
                    self.PanelCrash.gameObject:SetActiveEx(false)
                end
                local disableCountDown = disabledDay - currentDay
                -- 自毁倒计时
                if self.PanelTime then
                    self.PanelTime.gameObject:SetActiveEx(true)
                    -- 倒计时图片
                    local countDownIcon = self._Control:GetClientConfig("DisableCountDownIcon")
                    if countDownIcon then
                        if self.ImgTime then
                            self.ImgTime:SetSprite(countDownIcon)
                        end
                    end
                    if disableCountDown == 0 then
                        if self.TxtNum then
                            self.TxtNum.text = self._Control:GetClientConfig("DisableCountDownDesc", 2)
                        end
                    else
                        if self.TxtNum then
                            local countDownDesc = self._Control:GetClientConfig("DisableCountDownDesc", 1)
                            self.TxtNum.text = XUiHelper.FormatText(countDownDesc, disableCountDown)
                        end
                    end
                end
                if self.RImgCrashBg then
                    self.RImgCrashBg.gameObject:SetActiveEx(true)
                end
            else
                if self.PanelVisible then
                    self.PanelVisible.gameObject:SetActiveEx(false)
                end
                if self.PanelCrash then
                    self.PanelCrash.gameObject:SetActiveEx(true)
                end
                if self.PanelTime then
                    self.PanelTime.gameObject:SetActiveEx(false)
                end
                if self.RImgCrashBg then
                    self.RImgCrashBg.gameObject:SetActiveEx(false)
                end
                --if self._CrashState == CrashState.Normal then
                --    self._CrashState = CrashState.Crash
                --    self:PlayAnimation("PanelCrashEnable")
                --else
                --    self:StopAnimation("PanelCrashEnable")
                --end
            end
        else
            --self:StopAnimation("PanelCrashEnable")
            if self.PanelCrash then
                self.PanelCrash.gameObject:SetActiveEx(false)
            end
            if self.PanelTime then
                self.PanelTime.gameObject:SetActiveEx(false)
            end
            if self.RImgCrashBg then
                self.RImgCrashBg.gameObject:SetActiveEx(false)
            end
        end
    else
        self.PanelCrash.gameObject:SetActiveEx(false)
        --self:StopAnimation("PanelCrashEnable")
    end
end

return XUiPanelTheatre4BaseGrid
