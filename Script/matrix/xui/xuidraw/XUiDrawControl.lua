local XUiDrawControl = XClass(nil, "XUiDrawControl")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

local MAX_DRAW_BTN_COUNT = 2

---@class XUiDrawControl
function XUiDrawControl:Ctor(rootUi, drawInfo, drawCb, uiDraw)
    self.RootUi = rootUi
    self.DrawInfo = drawInfo
    self.DrawCb = drawCb
    self.UiDraw = uiDraw
    self.DrawBtns = {}
    self.IsCanDraw = true
    self._DrawTime = 0
    self:InitRes()
    self:InitButtons()
    return self
end

function XUiDrawControl:InitRes()
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.DrawInfo.UseItemId)
    self.TxtDrawCount = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, "TxtTotalDrawCount", "Text")
end

function XUiDrawControl:InitButtons()
    for i = 1, MAX_DRAW_BTN_COUNT do
        local btnName = "BtnDraw" .. i
        local btn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, btnName)
        if btn then
            self:InitButton(btn, i)
        end
    end
    ---@type UnityEngine.RectTransform
    self.FreeBtn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, "BtnDraw3")
    self.FreeTimeTip = self.FreeBtn:Find("Time/ImgBg/Txt"):GetComponent("Text")
    self.FreeBtn:GetComponent("XUiButton").CallBack = function() 
        self:OnDraw(1)
    end
end

function XUiDrawControl:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self:RefreshFreeTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshFreeTime()
    end,XScheduleManager.SECOND)
end

function XUiDrawControl:RefreshFreeTime()
    if XTool.UObjIsNil(self.RootUi.PanelDrawButtons) then
        self:StopTimer()
        return
    end
    local ticketInfo = XDataCenter.DrawManager.GetTicketInfoById(self.FreeTicketId)
    if ticketInfo and ticketInfo.ExpireTime then
        local now = XTime.GetServerNowTimestamp()
        local offset = ticketInfo.ExpireTime -  now
        if offset <= 0 then
            offset = 0
        end
        self.FreeTimeTip.text = CS.XTextManager.GetText("DrawFreeTicketCoolDown",XUiHelper.GetTime(offset))
    else
        self.FreeTimeTip.text = ""
    end

end

function XUiDrawControl:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

---@param btn UnityEngine.RectTransform
function XUiDrawControl:InitButton(btn, index)
    --@DATA
    local drawCount = self.DrawInfo.BtnDrawCount[index]
    local btnComponent = btn:GetComponent(typeof(CS.XUiComponent.XUiButton))
    btnComponent:SetNameByGroup(0, CS.XTextManager.GetText("DrawCount", drawCount))
    btnComponent:SetRawImage(self.UseItemIcon)
    btnComponent:SetNameByGroup(1, drawCount * self.DrawInfo.UseItemCount)

    self.DrawBtns[index] = {
        Tips = btn:FindTransform("ImgTips"),
        DrawCount = drawCount,
        Btn = btn
    }

    self.RootUi:RegisterClickEvent(btn:GetComponent("Button"), function()
        self:OnDraw(drawCount)
    end)
end

function XUiDrawControl:OnDraw(drawCount)
    local info
    local list

    if self.DrawInfo.CapacityCheckType == XDrawConfigs.DrawCapacityCheckType.Partner then
        if not XDataCenter.PartnerManager.CheckPartnerCount() then
            return
        end
    end

    if XDataCenter.EquipManager.CheckBoxOverLimitOfDraw() then
        return
    end

    -- CD冷却
    local nowTime = CS.XTimerManager.Ticks / 10000000
    if nowTime - self._DrawTime < tonumber(XDrawConfigs.GetDrawClientConfig("DrawCD")) then
        return
    end
    self._DrawTime = nowTime

    if XDataCenter.DrawManager.CheckDrawIsTimeOver(self.DrawInfo.Id) then
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end
    if not XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId) or (XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId) and drawCount ~= 1)  then
        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(self.DrawInfo.UseItemId,
                self.DrawInfo.UseItemCount,
                drawCount,
                function()
                    --self.UiDraw:UpdateItemCount()
                end,
                "DrawNotEnoughError") then
            return
        end
    end

    if self.IsCanDraw then
        self.IsCanDraw = false
        local onAnimFinish = function()
            if list and #list > 0 then
                self.IsCanDraw = true
                --self.UiDraw:PushShow(info, list)
            end
        end

        characterRecord.Record()
        local freeId = XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId) and XDataCenter.DrawManager.GetFreeTicketIdByGroupId(self.GroupId) or 0
        if freeId ~= 0 then
            XLog.Debug("使用了免费券 免费券Id:",freeId)
            XLog.Debug("使用了免费券 DrawId:",self.DrawInfo.Id)
        end
        if drawCount ~= 1 then
            freeId = 0
        end
        XDataCenter.DrawManager.DrawCard(self.DrawInfo.Id, drawCount,freeId, function(drawInfo, rewardList, extraRewardList)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            if self.DrawCb then
                self.DrawCb()
            end

            self:Update(drawInfo)
            info = drawInfo
            list = rewardList
            XLuaUiManager.OpenWithCallback("UiDrawNew", function()
                onAnimFinish()
            end, info,list)
            --self.UiDraw:SetExtraRewardList(extraRewardList)
            --self.UiDraw:HideUiView(onAnimFinish)
        end)
    end
end

function XUiDrawControl:Update(drawInfo,groupId)
    self.DrawInfo = drawInfo
    self.GroupId = groupId
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.DrawInfo.UseItemId)
    for i = 1, MAX_DRAW_BTN_COUNT do
        local btnName = "BtnDraw" .. i
        local btn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, btnName)
        if btn then
            ---@type XUiComponent.XUiButton
            local btnComponent = btn:GetComponent(typeof(CS.XUiComponent.XUiButton))
            local drawCount = self.DrawInfo.BtnDrawCount[i]
            btnComponent:SetNameByGroup(0, CS.XTextManager.GetText("DrawCount", drawCount))
            btnComponent:SetRawImage(self.UseItemIcon)
            btnComponent:SetNameByGroup(1, drawCount * self.DrawInfo.UseItemCount)
        end
    end

    if self.TxtDrawCount then
        self.TxtDrawCount.text = CS.XTextManager.GetText("DrawTotalCount", drawInfo.TotalCount)
    end
    
    --拥有免费券隐藏单抽按钮，显示免费抽按钮
    local isShowFreeBtn = XDataCenter.DrawManager.CheckHasFreeTicket(self.GroupId)
    local btnSingle = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, "BtnDraw1")
    local btnFree = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, "BtnDraw3")
    btnSingle.gameObject:SetActiveEx(not isShowFreeBtn)
    btnFree.gameObject:SetActiveEx(isShowFreeBtn)
    self.FreeTicketId = XDataCenter.DrawManager.GetFreeTicketIdByGroupId(self.GroupId)
    if isShowFreeBtn then
        self:StartTimer()
    else
        self:StopTimer()
    end
end

return XUiDrawControl