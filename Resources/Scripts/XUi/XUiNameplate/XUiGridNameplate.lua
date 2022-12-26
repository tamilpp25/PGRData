local XUiGridNameplate = XClass(nil, "XUiGridNameplate")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")


function XUiGridNameplate:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)

    self.UiPanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, rootUi)

    self.BtnSelect.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridNameplate:UpdateDataByGet(data, needSelClick, isHave)
    self.IsOnlyShow = true
    if data:IsNamepalteExpire() then
        self.TxtMedalName.text = CS.XTextManager.GetText("GetNamepalteIsExpire", data:GetNameplateName())
    else
        if isHave then
            self.TxtMedalName.text = CS.XTextManager.GetText("NameplateIsHave", data:GetNameplateName())
        else
            self.TxtMedalName.text = data:GetNameplateName()
        end
    end
    
    self.Data = data
    self.NeedSelClick = needSelClick
    self.UiPanelNameplate:UpdateDataById(data:GetNameplateId())

    self.PanelTime.gameObject:SetActiveEx(false)
    if not data:IsNamepalteExpire() then
        if not data:IsNamepalteForever() then
            self.PanelTime.gameObject:SetActiveEx(true)
            self:SetTimePanel(data:GetNamepalteLeftTime())
        end
    end
end

function XUiGridNameplate:UpdateData(data, needSelClick, isInList)
    self.PanelNew.gameObject:SetActiveEx(false)
    self.PanelTime.gameObject:SetActiveEx(false)
    self.LabelPress.gameObject:SetActiveEx(false)
    self.LabelLock.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)
    self.TxtMedalName.text = data:GetNameplateName()
    self.Data = data
    self.NeedSelClick = needSelClick
    self.IsInList = isInList
    self.UiPanelNameplate:UpdateDataById(data:GetNameplateId())
    if data:IsNameplateNew() then
        self.PanelNew.gameObject:SetActiveEx(true)
        if data:IsNameplateDress() then
            self.LabelPress.gameObject:SetActiveEx(true)
        end
    else
        if not data:IsNamepalteExpire() then
            if not data:IsNamepalteForever() then
                self.PanelTime.gameObject:SetActiveEx(true)
                self:SetTimePanel(data:GetNamepalteLeftTime())
            end
            
            if data:IsNameplateDress() then
                self.LabelPress.gameObject:SetActiveEx(true)
            end
            if self.PanelStale then
                self.PanelStale.gameObject:SetActiveEx(false)
            end   
        else
            if self.PanelStale then
                self.PanelStale.gameObject:SetActiveEx(true)
            end    
        end
    end 
end

function XUiGridNameplate:UpdateDataById(nameplateId, needSelClick, isInList, isInReward)
    self.PanelNew.gameObject:SetActiveEx(false)
    self.PanelTime.gameObject:SetActiveEx(false)
    self.LabelPress.gameObject:SetActiveEx(false)
    self.LabelLock.gameObject:SetActiveEx(false)
    
    self.Red.gameObject:SetActiveEx(false)
    self.TxtMedalName.text = XMedalConfigs.GetNameplateName(nameplateId)

    local data =  XDataCenter.MedalManager.CheckNameplateGroupUnluck(XMedalConfigs.GetNameplateGroup(nameplateId))
    if data and data:GetNameplateId() == nameplateId then
        self.Data = data
    end

    self.NeedSelClick = needSelClick
    self.IsInList = isInList
    self.UiPanelNameplate:UpdateDataById(nameplateId)
    if self.PanelStale then
        self.PanelStale.gameObject:SetActiveEx(false)
    end
    if not data or isInReward then
        return
    end
    if data:IsNameplateNew() then
        self.PanelNew.gameObject:SetActiveEx(true)
        if data:IsNameplateDress() then
            self.LabelPress.gameObject:SetActiveEx(true)
        end
    else
        if not data:IsNamepalteExpire() then
            if not data:IsNamepalteForever() then
                self.PanelTime.gameObject:SetActiveEx(true)
                self:SetTimePanel(data:GetNamepalteLeftTime())
            end
            
            if data:IsNameplateDress() then
                self.LabelPress.gameObject:SetActiveEx(true)
            end
            if self.PanelStale then
                self.PanelStale.gameObject:SetActiveEx(false)
            end   
        else
            if self.PanelStale then
                self.PanelStale.gameObject:SetActiveEx(true)
            end    
        end
    end 
end

function XUiGridNameplate:HideNewLabel()
    self.PanelNew.gameObject:SetActiveEx(false)
end

function XUiGridNameplate:HidePressLabel()
    self.LabelPress.gameObject:SetActiveEx(false)
end

function XUiGridNameplate:SetTimePanel(leftTime)
    if self.ImageTime then
        local sprite = nil
        local text = ""
        -- if XDataCenter.ItemManager.IsCanConvert(self.TemplateId) then
        --     sprite = XUiHelper.TagBgPath.Blue
        --     text = CS.XTextManager.GetText("ItemCanConvert")
        -- else
        if leftTime then
            text, sprite = XUiHelper.GetBagTimeLimitTimeStrAndBg(leftTime)
        end
        if sprite then
            self.ImageTime:SetSprite(sprite)
            self.ImageTime.gameObject:SetActive(true)
            self.TextTime.text = text or ""
        else
            self.ImageTime.gameObject:SetActive(false)
        end
    end
end

function XUiGridNameplate:OnBtnSelect()
    if self.NeedSelClick then
        XLuaUiManager.Open("UiNameplateTip", self.Data:GetNameplateId(), self.IsOnlyShow)
        if self.IsInList then
            XDataCenter.MedalManager.SetNameplateRedPointDic(self.Data:GetNameplateId())
        end
    end
end

return XUiGridNameplate