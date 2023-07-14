local XUiDrawControl = XClass(nil, "XUiDrawControl")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

local MAX_DRAW_BTN_COUNT = 3

function XUiDrawControl:Ctor(rootUi, drawInfo, drawCb, uiDraw)
    self.RootUi = rootUi
    self.DrawInfo = drawInfo
    self.DrawCb = drawCb
    self.UiDraw = uiDraw
    self.DrawBtns = {}
    self.IsCanDraw = true
    self:InitRes()
    self:InitButtons()
    self:Update(drawInfo)
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

    if XDataCenter.DrawManager.CheckDrawIsTimeOver(self.DrawInfo.Id) then
        XUiManager.TipText("DrawAimLeftTimeOver")
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(self.DrawInfo.UseItemId,
            self.DrawInfo.UseItemCount,
            drawCount,
            function()
                --self.UiDraw:UpdateItemCount()
            end,
            "DrawNotEnoughError") then
        return
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

        XDataCenter.DrawManager.DrawCard(self.DrawInfo.Id, drawCount, function(drawInfo, rewardList, extraRewardList)
            XDataCenter.AntiAddictionManager.BeginDrawCardAction()
            if self.DrawCb then
                self.DrawCb()
            end

            self:Update(drawInfo)
            info = drawInfo
            list = rewardList
            XLuaUiManager.Open("UiDrawNew",info,list)
            --self.UiDraw:SetExtraRewardList(extraRewardList)
            --self.UiDraw:HideUiView(onAnimFinish)
            onAnimFinish()
            self:SetDrawEvent(drawInfo,drawCount)
        end, function()
            self.IsCanDraw = true
        end)
    end
end

function XUiDrawControl:SetDrawEvent(drawInfo, drawCount)
    if drawCount < 10 then
        return
    end
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawInfo.Id)
    if combination then
        if combination.Type == XDrawConfigs.CombinationsTypes.Aim then
            local aimType = combination.GoodsId[1]
            if aimType ~= nil then
                aimType = XArrangeConfigs.GetType(aimType)
            end
            if not aimType or aimType == XArrangeConfigs.Types.Character then
                --CheckPoint: APPEVENT_DRAWS_ROLE_10_1
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_role_10)
            else
                --CheckPoint: APPEVENT_DRAWS_WEAPON_10_1
                XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_weapon_10)
            end
        elseif combination.Type == XDrawConfigs.CombinationsTypes.NewUp then
            --CheckPoint: APPEVENT_DRAWS_LIMIT_10
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_limit_10)
        end
    else
        if drawInfo.Id == 101 then
            --CheckPoint: APPEVENT_DRAWS_ROLE_10_2
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_role_10)
        elseif drawInfo.Id == 201 then
            --CheckPoint: APPEVENT_DRAWS_WEAPON_10_2
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.draws_weapon_10)
        end
    end
end
function XUiDrawControl:Update(drawInfo)
    self.DrawInfo = drawInfo
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
end

return XUiDrawControl