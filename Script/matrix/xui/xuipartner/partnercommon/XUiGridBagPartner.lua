local PanelUsingWords = CS.XTextManager.GetText("EquipGridUsingWords")
local PanelInPrefabWords = CS.XTextManager.GetText("EquipGridInPrefabWords")

local XUiGridBagPartner = XClass(nil, "XUiGridBagPartner")

function XUiGridBagPartner:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsSelect = false
    self.ClickCb = clickCb
    XTool.InitUiObject(self)
    self:InitUi()
    self:SetButtonCallBack()
    self:SetSelected(false)
end

function XUiGridBagPartner:InitUi()
    self.TextUsing = self.PanelUsing:Find("TextUsing"):GetComponent("Text")
    --v1.28 装备头像
    self.RImgRole = self.PanelUsing.transform:Find("RImgRole"):GetComponent("RawImage")
    self.PanelDefault = self.GameObject.transform:Find("PanelDefault")
    self.TextInPrefab = self.PanelDefault.transform:Find("TextUsing"):GetComponent("Text")
end

function XUiGridBagPartner:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        self:OnBtnClickClick()
    end
end

function XUiGridBagPartner:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.Data, self)
    end
end

function XUiGridBagPartner:UpdateGrid(data, isInPrefab)
    self.Data = data
    if data then
        self.RImgIcon:SetRawImage(data:GetIcon())
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(data:GetQuality()))
        self.ImgBreak:SetSprite(data:GetBreakthroughIcon())
        self.TxtLevel.text = data:GetLevel()
        self.TxtName.text = data:GetName()
        self.ImageQuality:SetSprite(XPartnerConfigs.GeQualityBgPath(data:GetInitQuality()))
        self.ImgLock.gameObject:SetActiveEx(data:GetIsLock())
        --v1.28 装备头像
        if data:GetIsCarry() then
            self.PanelUsing.gameObject:SetActiveEx(true)
            self.PanelDefault.gameObject:SetActiveEx(false)
            self.TextUsing.text = PanelUsingWords
            if not XTool.UObjIsNil(self.RImgRole) then
                local icon = XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(data:GetCharacterId())
                self.RImgRole:SetRawImage(icon)
            end
        elseif isInPrefab then
            self.PanelUsing.gameObject:SetActiveEx(false)
            self.PanelDefault.gameObject:SetActiveEx(true)
            self.TextInPrefab.text = PanelInPrefabWords
        else
            self.PanelUsing.gameObject:SetActiveEx(false)
            self.PanelDefault.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridBagPartner:SetSelected(status)
    self.ImgSelect.gameObject:SetActiveEx(status)
end

return XUiGridBagPartner