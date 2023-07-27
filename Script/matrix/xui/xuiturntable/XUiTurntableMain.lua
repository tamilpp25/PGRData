local XUiGridTurntableProgressReward = require("XUi/XUiTurntable/XUiGridTurntableProgressReward")

local Tweening = CS.DG.Tweening
local Quaternion = CS.UnityEngine.Quaternion
local TurntableAngleOffset = CS.XGame.ClientConfig:GetInt("TurntableAngleOffset")

---@class XUiTurntableMain : XLuaUi
---@field _Control XTurntableControl
local XUiTurntableMain = XLuaUiManager.Register(XLuaUi, "UiTurntableMain")

function XUiTurntableMain:OnAwake()
    self:RegisterClickEvent(self.BtnTask, handler(self, self.OnBtnTaskClick))
    self:RegisterClickEvent(self.BtnOne, handler(self, self.OnOneTurntableClick))
    self:RegisterClickEvent(self.BtnTen, handler(self, self.OnTenTurntableClick))
    self:RegisterClickEvent(self.BtnDetails, handler(self, self.OnBtnRecordClick))
    self:RegisterClickEvent(self.BtnSkip, handler(self, self.OnPopUpClick))
    self:RegisterClickEvent(self.PanelObtainpointsTips1, handler(self, self.OnBtnObtainClick))
    self:RegisterClickEvent(self.PanelObtainpointsTips2, handler(self, self.OnBtnObtainClick))
end

function XUiTurntableMain:OnStart()
    self._LinePool = {}
    self._SectorsPool = {}
    self._BoxPool = {}
    self._EffectPool = {}

    self:InitCompnent()
    self:InitActivityInfo()
    self:InitProgress()
    self:UpdateTurntable()
    self:UpdateTurntableButton()
    self:UpdateRedPoint()
    self:UpdateBtnSkip()
    self:OnBtnObtainClick()
end

function XUiTurntableMain:OnGetEvents()
    return { XEventId.EVENT_FINISH_TASK, XEventId.EVENT_TASK_SYNC }
end

function XUiTurntableMain:OnNotify(evt, ...)
    self:UpdateRedPoint()
end

function XUiTurntableMain:InitCompnent()
    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite, handler(self, self.OnBtnCloseClick),handler(self,self.OnBtnMainClick))

    local itemId, _ = self._Control:GetTurntableCost()
    local itemCfg = XDataCenter.ItemManager.GetItem(itemId)
    if itemCfg then -- 道具过期
        if not self.AssetPanel then
            self.AssetPanel = XUiHelper.NewPanelActivityAsset({ itemId }, self.PanelSpecialTool)
        else
            self.AssetPanel:Refresh({ itemId })
        end
        XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
            self:UpdateTurntableButton()
        end, self)
        self.PanelSpecialTool.gameObject:SetActiveEx(true)
    else
        self.PanelSpecialTool.gameObject:SetActiveEx(false)
    end

    self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
    self.PanelForbidClick.gameObject:SetActiveEx(false)
end

function XUiTurntableMain:InitActivityInfo()
    self:RemoveTimer()
    self:CountDown()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:CountDown()
    end, XScheduleManager.SECOND, 0)
end

function XUiTurntableMain:InitProgress()
    if not self._rewards then
        ---@type table<number, XUiGridTurntableProgressReward>
        self._rewards = {}
    end

    local idx = 0
    local rewards = self._Control:GetProgressRewards()
    for i = #rewards, 1, -1 do
        local cell = i == #rewards and self.RewardRoot or XUiHelper.Instantiate(self.RewardRoot, self.RewardRoot.parent)
        self._rewards[i] = XUiGridTurntableProgressReward.New(cell, self)
        self._rewards[i]:Init(i, rewards[i][1], rewards[i][2])
        if self._rewards[i]:GetIsGain() then
            idx = idx + 1
        end
    end

    self:UpdateProgressBar()
    self:ScrollTo(idx, #rewards)
end

function XUiTurntableMain:UpdateBtnSkip()
    self._IsJump = self._Control:GetSkipAnimationValue()
    self.BtnSkip:SetButtonState(self._IsJump and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiTurntableMain:UpdateTurntableButton()
    self._CostItemId, self._OneCoseNum = self._Control:GetTurntableCost()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(self._CostItemId)
    local itemCount = XDataCenter.ItemManager.GetCount(self._CostItemId)

    self.BtnOne:SetNameByGroup(0, XUiHelper.GetText("TurntableRotateTimes", 1))
    self.BtnOne:SetNameByGroup(1, itemCount >= self._OneCoseNum and string.format("×%s", self._OneCoseNum) or string.format("<color='#FF0F0F'>×%s</color>", self._OneCoseNum))
    self.BtnOne:SetRawImage(icon)

    local remain = self._Control:RemainingItemsCount()
    local drawNum = self._Control:GetMaxDrawNum()
    local isOver = self._Control:IsGoodsGone()
    self._MultiTimes = (remain >= drawNum or isOver) and drawNum or remain
    self._TenCostNum = self._MultiTimes * self._OneCoseNum
    self.BtnTen:SetNameByGroup(0, XUiHelper.GetText("TurntableRotateTimes", self._MultiTimes))
    self.BtnTen:SetNameByGroup(1, itemCount >= self._TenCostNum and string.format("×%s", self._TenCostNum) or string.format("<color='#FF0F0F'>×%s</color>", self._TenCostNum))
    self.BtnTen:SetRawImage(icon)
end

function XUiTurntableMain:UpdateRedPoint()
    local isRed = self._Control:CanTaskRewardGain(1) or self._Control:CanTaskRewardGain(2)
    self.BtnTask:ShowReddot(isRed)
end

function XUiTurntableMain:UpdateTurntable()
    local goods = {}
    local totalAverage = 0
    local totalAngle = 0
    local isOver = self._Control:IsGoodsGone()
    self._IdMap = {}
    self._EffectPool = {}
    self._Config = self._Control:GetTurntableRewards()
    for _, config in pairs(self._Config) do
        local hasGainTimes = self._Control:GetItemGainTimes(config.Id)
        local remindTimes = isOver and config.CanGainTimes or config.CanGainTimes - hasGainTimes
        if remindTimes > 0 then
            table.insert(goods, { config.Id, config.InitialAngle })
            self._IdMap[config.Id] = #goods
        else
            totalAverage = totalAverage + config.InitialAngle
        end
        totalAngle = totalAngle + config.InitialAngle
    end
    -- 如果策划配置错误 全部角度加起来不是360° 则log提示
    if totalAngle ~= 360 then
        XLog.Error("角度配置错误了，总角度是" .. totalAngle .. ",不是360°")
    end
    -- 已经抽取完的道具的角度要平均到其他道具上面
    if totalAverage > 0 then
        local average = totalAverage / #goods
        for i, _ in ipairs(goods) do
            goods[i][2] = goods[i][2] + average
        end
    end

    table.sort(goods, function(a, b)
        return a[1] < b[1]
    end)

    self._LightMap = {}
    ---@type number[]
    self._RotationTb = {}
    self._RotateOffect = 360 - self.PanleRing.localEulerAngles.z -- 大转盘本身有角度
    local rotation = 270
    for i, info in ipairs(goods) do
        local light = {}
        local angle = info[2]
        local cfg = self._Control:GetTurntableById(info[1])
        -- 设置扇形
        local sector = self._SectorsPool[i]
        if not sector then
            sector = i == 1 and self.Sector or XUiHelper.Instantiate(self.Sector, self.Sector.parent)
            self._SectorsPool[i] = sector
        end
        local fillAmount = angle / 360
        self:SetSector(sector, cfg, fillAmount, rotation, isOver, light)

        -- 设置扇形边线
        local line = self._LinePool[i]
        if not line then
            line = i == 1 and self.ImgLine or XUiHelper.Instantiate(self.ImgLine, self.ImgLine.parent)
            self._LinePool[i] = line
        end
        self:SetLine(line, rotation)

        -- 设置文本和道具
        local box = self._BoxPool[i]
        if not box then
            box = i == 1 and self.PanelIcon or XUiHelper.Instantiate(self.PanelIcon, self.PanelIcon.parent)
            self._BoxPool[i] = box
        end
        local boxRotation = rotation - angle / 2 - 180
        self:SetItem(box, cfg, boxRotation, isOver)

        -- 指针经过时高亮
        light.startRotation = rotation
        light.endRotation = rotation - angle
        table.insert(self._LightMap, light)

        rotation = rotation - angle
        self._RotationTb[i] = rotation
    end

    -- 隐藏
    for i = #goods + 1, #self._SectorsPool do
        self._SectorsPool[i].gameObject:SetActiveEx(false)
    end
    local idx = #goods <= 1 and 1 or #goods + 1 -- 只有1种道具时不需要显示边线
    for i = idx, #self._LinePool do
        self._LinePool[i].gameObject:SetActiveEx(false)
    end
    for i = #goods + 1, #self._BoxPool do
        self._BoxPool[i].gameObject:SetActiveEx(false)
    end

    self.BoxArrow.localRotation = Quaternion.Euler(0, 0, 0)
    self.TxtTimes.text = XUiHelper.GetText("TurntableTimes", self._Control:GetRotateTimes())
    self.RawImageZz.gameObject:SetActiveEx(isOver)
end

function XUiTurntableMain:SetSector(sector, cfg, fillAmount, rotation, isOver, light)
    sector.gameObject:SetActiveEx(true)
    local uiObject = {}
    XTool.InitUiObjectByUi(uiObject, sector)
    uiObject.Sector.localRotation = Quaternion.Euler(0, 0, rotation)
    local showSectors = {}
    showSectors[XEnumConst.Turntable.RewardType.Main] = uiObject.RingHuang
    showSectors[XEnumConst.Turntable.RewardType.Height] = uiObject.RingZi
    showSectors[XEnumConst.Turntable.RewardType.Simple] = uiObject.RingLan
    local lights = {}
    lights[XEnumConst.Turntable.RewardType.Main] = uiObject.RingHuangLight
    lights[XEnumConst.Turntable.RewardType.Height] = uiObject.RingZiLight
    lights[XEnumConst.Turntable.RewardType.Simple] = uiObject.RingLanLight
    local masks = {}
    masks[XEnumConst.Turntable.RewardType.Main] = uiObject.RingHuangKong
    masks[XEnumConst.Turntable.RewardType.Height] = uiObject.RingZiKong
    masks[XEnumConst.Turntable.RewardType.Simple] = uiObject.RingLanKong
    for type, img in pairs(showSectors) do
        if type == cfg.RewardType then
            if isOver then
                img.gameObject:SetActiveEx(false)
            else
                img.gameObject:SetActiveEx(true)
            end
            img.fillAmount = fillAmount
        else
            img.gameObject:SetActiveEx(false)
        end
    end
    for type, img in pairs(lights) do
        if type == cfg.RewardType then
            img.fillAmount = fillAmount
        end
        img.gameObject:SetActiveEx(false)
    end
    for type, img in pairs(masks) do
        if type == cfg.RewardType then
            if isOver then
                img.gameObject:SetActiveEx(true)
            else
                img.gameObject:SetActiveEx(false)
            end
            img.fillAmount = fillAmount
        else
            img.gameObject:SetActiveEx(false)
        end
    end

    light.imgCircle = lights[cfg.RewardType]
end

function XUiTurntableMain:SetLine(line, rotation)
    line.gameObject:SetActiveEx(true)
    line.localRotation = Quaternion.Euler(0, 0, rotation - 180)
end

function XUiTurntableMain:SetItem(box, cfg, boxRotation, isOver)
    box.gameObject:SetActiveEx(true)
    box.localRotation = Quaternion.Euler(0, 0, boxRotation)
    local isMain = cfg.RewardType == XEnumConst.Turntable.RewardType.Main
    local uiObject = {}
    XTool.InitUiObjectByUi(uiObject, box)
    local grid = XUiGridCommon.New(self, isMain and uiObject.Grid256NewBig or uiObject.Grid256NewSmall)
    local itemId, itemCount = self._Control:GetItemByRewardId(cfg.RewardId)
    local costNum = isOver and 0 or self._Control:GetItemGainTimes(cfg.Id)
    local rewardData = XRewardManager.CreateRewardGoods(itemId, itemCount)
    grid:Refresh(rewardData)
    grid.ImgQuality.gameObject:SetActiveEx(false)
    grid:SetName("")
    grid:SetProxyClickFunc(function()
        self:OnShowItemTip(rewardData)
    end)
    if isMain then -- 部分道具Icon中心点不对 直接旋转的话位置会有问题 所以这里旋转它的父物体
        uiObject.IconDajiangBig.localRotation = Quaternion.Euler(0, 0, self._RotateOffect - boxRotation)
    else
        uiObject.IconDajiangSmall.localRotation = Quaternion.Euler(0, 0, self._RotateOffect - boxRotation)
    end
    uiObject.TxtNum.transform.localRotation = Quaternion.Euler(0, 0, self._RotateOffect - boxRotation)
    uiObject.TxtNum.text = string.format("×%s", cfg.CanGainTimes - costNum)
    uiObject.TxtNum.gameObject:SetActiveEx(not isMain)
    uiObject.Grid256NewBig.gameObject:SetActiveEx(isMain)
    uiObject.Grid256NewSmall.gameObject:SetActiveEx(not isMain)
    uiObject.IconDajiangBig.gameObject:SetActiveEx(isMain)
    uiObject.IconDajiangSmall.gameObject:SetActiveEx(not isMain)

    if isMain then
        self._EffectPool[cfg.Id] = uiObject.PanelEffectBig
    else
        self._EffectPool[cfg.Id] = uiObject.PanelEffectSmall
    end
end

function XUiTurntableMain:UpdateProgress()
    for _, reward in pairs(self._rewards) do
        reward:Update()
    end
    self:UpdateProgressBar()
end

function XUiTurntableMain:UpdateProgressBar()
    local rewards = self._Control:GetProgressRewards()
    local space = self.RewardRoot.sizeDelta.y
    local totalHeight = space * (#rewards - 1) + 60
    local ratio = 60 / totalHeight -- 第一部分比其他的短
    local min = rewards[1][2]
    local max = rewards[#rewards][2]
    local times = self._Control:GetRotateTimes()
    local value = 0
    if times <= min then
        value = times / min * ratio
    else
        value = (times - min) / (max - min) * (1 - ratio) + ratio
    end
    self.ImgProgress.fillAmount = value
end

function XUiTurntableMain:ScrollTo(idx, total)
    local cellHeight = self.RewardRoot.sizeDelta.y
    local scrollHeight = cellHeight * total - self.View.sizeDelta.y
    self.ScrollView.verticalNormalizedPosition = math.min(1, idx * cellHeight / scrollHeight)
end

function XUiTurntableMain:OnShowItemTip(data)
    if self._IsTweening then
        return
    end
    XLuaUiManager.Open("UiTip", data)
end

function XUiTurntableMain:OnBtnStartClick(isTen)
    if self._IsTweening then
        return
    end

    if self._Control:IsGoodsGone() then
        XUiManager.TipError(XUiHelper.GetText("TurntableNoItemTip"))
        return
    end

    local ownItemCount = XDataCenter.ItemManager.GetCount(self._CostItemId)
    local spendCount = isTen and self._TenCostNum or self._OneCoseNum
    if ownItemCount < spendCount then
        local itemName = XDataCenter.ItemManager.GetItemName(self._CostItemId)
        XUiManager.TipError(XUiHelper.GetText("MoeWarDailyVoteItemNotEnoughTip", string.format("【%s】", itemName)))
        return
    end

    local count = isTen and self._MultiTimes or 1
    self._Control:RequestDrawReward(count, function(records)
        self:StartRotate(records)
    end)
end

function XUiTurntableMain:StartRotate(records)
    self:OnTurntableStart()

    local dim = nil
    local dimRewardId = nil
    for _, v in pairs(records) do
        local cfg = self._Control:GetTurntableById(v.Id)
        if not dim and cfg.RewardType == XEnumConst.Turntable.RewardType.Main then
            dimRewardId = v.Id
            dim = self._IdMap[dimRewardId]
        end
    end
    if not dim then
        dimRewardId = records[1].Id
        dim = self._IdMap[dimRewardId]
    end

    local cur = dim == 1 and self._RotationTb[#self._RotationTb] or self._RotationTb[dim - 1]
    local next = dim == 1 and self._RotationTb[dim] - 360 or self._RotationTb[dim]
    local range = math.floor(math.abs(cur - next))
    local random
    if range > TurntableAngleOffset * 2 then
        random = math.ceil(next) + math.random(TurntableAngleOffset, range - TurntableAngleOffset)
    else
        random = math.ceil(next) + math.random(0, range)
    end
    local rotation = 180 + random - 360 * 8

    if self._IsJump then
        self:PlayEndEffect(records, dimRewardId)
        self:OnTurntableEndUpdate()
    else
        self.BoxArrow:DOLocalRotate(CS.UnityEngine.Vector3(0, 0, rotation), 6, Tweening.RotateMode.FastBeyond360):SetEase(Tweening.Ease.OutQuart):OnUpdate(function()
            self:ShowLight() -- 指针所指区域高亮
        end):OnComplete(function()
            self:PlayEndEffect(records, dimRewardId)
            self:OnTurntableEndUpdate()
            self:PlayEndAnimation()
        end)
        self:PlayStartAnimation()
    end
end

function XUiTurntableMain:PlayStartAnimation()
    self.Spine = self.PanelSpine:LoadSpinePrefab(self.PanelSpine.AssetUrl):GetComponent("SkeletonGraphic")
    if self.Spine then
        self.Spine.AnimationState:SetAnimation(0, "idle2", true)
    end
    self:PlayAnimation("ChoukaShake")
end

function XUiTurntableMain:PlayEndAnimation()
    if self.Spine then
        self.Spine.AnimationState:SetAnimation(0, "idle", true)
    end
end

function XUiTurntableMain:PlayEndEffect(records, dim)
    self._IsTweening = false
    local effectPanel = self._EffectPool[dim]
    if effectPanel then
        effectPanel.gameObject:SetActiveEx(true)
        self._EffectTimer = XScheduleManager.ScheduleOnce(function()
            effectPanel.gameObject:SetActiveEx(false)
            self:OnTurntableEnd(records)
        end, 1000)
    else
        self:OnTurntableEnd(records)
    end
    if self.RawImageLight then
        self._ImgShowTimer = XScheduleManager.ScheduleOnce(function()
            self.RawImageLight.gameObject:SetActiveEx(true)
            self._ImgHideTimer = XScheduleManager.ScheduleOnce(function()
                self.RawImageLight.gameObject:SetActiveEx(false)
            end, 900)
        end, 100)
    end
end

function XUiTurntableMain:OnTurntableEndUpdate()
    self:UpdateProgress()
    self:UpdateTurntableButton()
    self:UpdateRedPoint()
end

function XUiTurntableMain:OnTurntableStart()
    self._IsTweening = true
    self.BtnSkip.enabled = false
    self.PanelForbidClick.gameObject:SetActiveEx(true)
    self:SetIsRewardCanGain()
end

function XUiTurntableMain:OnTurntableEnd(records)
    self.BtnSkip.enabled = true
    self.PanelForbidClick.gameObject:SetActiveEx(false)
    self:ShowRewardTip(records)
    self:UpdateTurntable()
    self:SetIsRewardCanGain()
end

function XUiTurntableMain:SetIsRewardCanGain()
    for _, v in pairs(self._rewards) do
        v:SetForbidGain(self._IsTweening)
    end
end

function XUiTurntableMain:ShowLight()
    if not self._IsTweening then
        return
    end
    local rotation = self.BoxArrow.localEulerAngles.z - 180
    if rotation < 0 then
        rotation = rotation + 360
    end
    for _, v in ipairs(self._LightMap) do
        local isShow = false
        if v.startRotation > 0 and v.endRotation < 0 then
            isShow = v.startRotation >= rotation or 360 + v.endRotation < rotation
        elseif v.startRotation < 0 and v.endRotation < 0 then
            isShow = 360 + v.startRotation >= rotation and 360 + v.endRotation < rotation
        else
            isShow = v.startRotation >= rotation and v.endRotation < rotation
        end
        v.imgCircle.gameObject:SetActiveEx(isShow)
    end
end

function XUiTurntableMain:ShowRewardTip(records)
    local isBigTip = #records > 5
    local list = isBigTip and self.ListBig or self.ListSmall
    local panel = isBigTip and self.PanelSettllement01 or self.PanelSettllement02
    local nameStr = isBigTip and "UiTurntableBig" or "UiTurntableSmall"
    self:RefreshTemplateGrids(self.GridGain, records, list, nil, nameStr, function(grid, data)
        self:InitReward(grid, data)
    end)
    panel.gameObject:SetActiveEx(true)
end

function XUiTurntableMain:InitReward(grid, data)
    local param = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.RewardGoods.TemplateId)
    grid.RImgIcon:SetRawImage(param.BigIcon)
    grid.TxtScore.text = "×" .. data.RewardGoods.Count
    local cfg = self._Control:GetTurntableById(data.Id)
    grid.EffectHight.gameObject:SetActiveEx(cfg.RewardType == XEnumConst.Turntable.RewardType.Main)
    XUiHelper.SetQualityIcon(self, grid.ImgQuality, param.Quality)
    if param.Site and param.Site ~= XEquipConfig.EquipSite.Weapon then
        grid.PanelSite.gameObject:SetActiveEx(true)
        grid.TxtSite.text = "0" .. param.Site
    else
        grid.PanelSite.gameObject:SetActiveEx(false)
    end
end

function XUiTurntableMain:OnBtnCloseClick()
    if self._IsTweening then
        return
    end
    self:Close()
end

function XUiTurntableMain:OnBtnMainClick()
    if self._IsTweening then
        return
    end
    XLuaUiManager.RunMain()
end

function XUiTurntableMain:OnOneTurntableClick()
    self:OnBtnStartClick(false)
end

function XUiTurntableMain:OnTenTurntableClick()
    self:OnBtnStartClick(true)
end

function XUiTurntableMain:OnBtnRecordClick()
    if self._IsTweening then
        return
    end
    if not XLuaUiManager.IsUiShow("UiTurntableLog") then
        self:OpenOneChildUi("UiTurntableLog", self)
    end
    self:FindChildUiObj("UiTurntableLog"):Refresh(true)
end

function XUiTurntableMain:OnBtnTaskClick()
    if self._IsTweening then
        return
    end
    if not XLuaUiManager.IsUiShow("UiTurntableTask") then
        self:OpenOneChildUi("UiTurntableTask", self)
    end
    self:FindChildUiObj("UiTurntableTask"):Refresh(true)
end

function XUiTurntableMain:OnPopUpClick()
    self._IsJump = self.BtnSkip:GetToggleState()
    self._Control:SaveSkipAnimationValue(self._IsJump)
end

function XUiTurntableMain:OnBtnObtainClick()
    self.PanelSettllement01.gameObject:SetActiveEx(false)
    self.PanelSettllement02.gameObject:SetActiveEx(false)
end

function XUiTurntableMain:OnDestroy()
    self._LinePool = {}
    self._SectorsPool = {}
    self._BoxPool = {}
    self._IsTweening = false
    self:RemoveTimer()
    self._Control:SignDontShow72hoursRedPoint()
end

function XUiTurntableMain:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    if self._EffectTimer then
        XScheduleManager.UnSchedule(self._EffectTimer)
    end
    if self._ImgShowTimer then
        XScheduleManager.UnSchedule(self._ImgShowTimer)
    end
    if self._ImgHideTimer then
        XScheduleManager.UnSchedule(self._ImgHideTimer)
    end
    self.Timer = nil
    self._EffectTimer = nil
    self._ImgShowTimer = nil
    self._ImgHideTimer = nil
end

function XUiTurntableMain:CountDown()
    local time = self._Control:EndTime()
    if time > 0 then
        self.TxtTime.text = XUiHelper.GetText("TurntableTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    else
        XLog.Debug("大转盘活动结束，自动关闭界面.")
        self:Close()
    end
end

return XUiTurntableMain