XUiBattery = XClass(nil, "XUiBattery")
local GoodsId = 1
local RewardIndex = 2
local FoEver = 0
local FoEverText = CS.XTextManager.GetText("Forever")
local OverdueText = CS.XTextManager.GetText("TaskStateOverdue")
local BatteryOverSelectItemNumText = CS.XTextManager.GetText("BatteryOverSelectItemNum")
local LONG_CLICK_TIME = 300

function XUiBattery:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = ui
    XTool.InitUiObject(self)

    self.IsLockLongClick = false
    self:FlushSelectShow()
    self:AutoAddListener()
end

function XUiBattery:OnRecycle()
    if self.Timers then
        XScheduleManager.UnSchedule(self.Timers)
        self.Timers = nil
    end
end

function XUiBattery:AutoAddListener()
    self.BtnClick.CallBack = function()
        self:OnBtnClick()
    end
    self.BtnMinusSelect.CallBack = function()
        self:OnBtnMinusSelectCallBack()
    end
    -- 添加长按事件
    local btnClickPointer = self.BtnClick.gameObject:GetComponent("XUiPointer")
    if btnClickPointer then
        XUiButtonLongClick.New(btnClickPointer, 100, self, nil, self.OnBtnLongClick, nil, true)
    end
    local btnMinusSelect = self.BtnMinusSelect:GetComponent("XUiPointer")
    XUiButtonLongClick.New(btnMinusSelect, 10, self, nil, self.OnBtnMinusSelectLongClick, nil, true)
end

function XUiBattery:OnBtnLongClick(time)
    if self.IsCantUse then
        XUiManager.TipError(OverdueText)
        return
    end
    local selectItemCount = self.Base:GetSelectItemCountByIndex(self.Index)
    if selectItemCount >= self.BagItem.Count then
        XUiManager.TipMsg(BatteryOverSelectItemNumText)
        return
    end
    self:SetSelectedCount(selectItemCount + 1)
end

function XUiBattery:OnBtnClick()
    if not self.IsCantUse then
        local selectItemCount = self.Base:GetSelectItemCountByIndex(self.Index)
        if selectItemCount < self.BagItem.Count then
            self:SetSelectedCount(selectItemCount + 1)
        else
            XUiManager.TipMsg(BatteryOverSelectItemNumText)
        end
    else
        XUiManager.TipError(OverdueText)
    end
end

function XUiBattery:SetSelectedCount(count)
    local onecElectricNum = self:GetOneElectricCount()
    self.Base:SetSelectItemCount(self.Index, count, onecElectricNum)
    self:FlushSelectShow()
end

function XUiBattery:OnBtnMinusSelectCallBack()
    self.Base:SubSelectItemCountByIndex(self.Index)
    self:FlushSelectShow()
end

function XUiBattery:OnBtnMinusSelectLongClick(time)
    if self.IsLockLongClick or time <= LONG_CLICK_TIME then
        return
    end

    if time > LONG_CLICK_TIME then
        self.IsLockLongClick = true
        self.BtnMinusSelect:SetButtonState(CS.UiButtonState.Normal)
    end
    self.Base:ClearSelectItemCountByIndex(self.Index)
    self:FlushSelectShow()
    self.IsLockLongClick = false
end

function XUiBattery:UpdateGrid(bagItem, parent, index)
    self.Base = parent
    self.BagItem = bagItem
    self.Index = index
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.BagItem.Data.Id)

    local count = bagItem.Count
    -- 数量
    if self.TxtCount and count then
        self.TxtCount.text = CS.XTextManager.GetText("ShopGridCommonCount", count)
    end

    -- 图标
    if self.RImgIcon then
        local icon = self.GoodsShowParams.Icon
        if icon and #icon > 0 then
            self.RImgIcon:SetRawImage(icon)
        end
    end

    if self.ImgQuality and self.GoodsShowParams.Quality then
        local qualityIcon = self.GoodsShowParams.QualityIcon

        if qualityIcon then
            parent:SetUiSprite(self.ImgQuality, qualityIcon)
        else
            XUiHelper.SetQualityIcon(parent, self.ImgQuality, self.GoodsShowParams.Quality)
        end
    end

    if self.BagItem.Data.Template.TimelinessType and
    self.BagItem.Data.Template.TimelinessType ~= FoEver and not self.Timers then
        self.Timers = XScheduleManager.ScheduleForever(function() self:SetTime() end, XScheduleManager.SECOND)
    end

    self:SetTime()
    self:FlushSelectShow()
end

function XUiBattery:SetTime()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local sprite
    if not self.BagItem.Data.Template.TimelinessType or
    self.BagItem.Data.Template.TimelinessType == FoEver then
        self.TxtTime.text = FoEverText
        sprite = XUiHelper.TagBgPath.Green
        self.IsCantUse = false
    else
        local LifeTime = self.BagItem.RecycleBatch and self.BagItem.RecycleBatch.RecycleTime - XTime.GetServerNowTimestamp()
        or XDataCenter.ItemManager.GetRecycleLeftTime(self.BagItem.Data.Id)

        if LifeTime and LifeTime > 0 then
            local tmpTime = XUiHelper.GetTime(LifeTime, XUiHelper.TimeFormatType.MAINBATTERY)
            self.TxtTime.text = tmpTime
            if LifeTime > CS.XDateUtil.ONE_DAY_SECOND * 7 then
                sprite = XUiHelper.TagBgPath.Green
            elseif LifeTime > CS.XDateUtil.ONE_DAY_SECOND then
                sprite = XUiHelper.TagBgPath.Yellow
            else
                sprite = XUiHelper.TagBgPath.Red
            end
            self.IsCantUse = false
        else
            self.TxtTime.text = OverdueText
            sprite = XUiHelper.TagBgPath.Red
            self.IsCantUse = true
            self:OnBtnMinusSelectCallBack()
        end
    end
    if self.Base then
        self.Base:SetUiSprite(self.TimeTag, sprite)
    end
end

function XUiBattery:FlushSelectShow()
    if self.Base then
        local selectItemCount = self.Base:GetSelectItemCountByIndex(self.Index)
        self:SetSelectItemCountText(selectItemCount)
        self:CheckShowSelect()
    end
end

function XUiBattery:SetSelectItemCountText(selectItemCount)
    if self.TxtSelectHide then
        self.TxtSelectHide.text = selectItemCount
    end
end

function XUiBattery:GetOneElectricCount()
    local goodsList = XRewardManager.GetRewardList(self.BagItem.Data.Template.SubTypeParams[RewardIndex])
    return goodsList[GoodsId].Count
end

function XUiBattery:CheckShowSelect()
    local selectItemCount = self.Base:GetSelectItemCountByIndex(self.Index)
    self.ImgSelect.gameObject:SetActiveEx(selectItemCount > 0)
    self.BtnMinusSelect.gameObject:SetActiveEx(selectItemCount > 0)
    self.TxtSelectHide.gameObject:SetActiveEx(selectItemCount > 0)
end

return XUiBattery