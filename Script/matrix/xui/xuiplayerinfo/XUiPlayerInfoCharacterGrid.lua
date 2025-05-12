local XUiPlayerInfoCharacterGrid = XClass(nil, "XUiPlayerInfoCharacterGrid")
local XEquip = require("XEntity/XEquip/XEquip")
local XPartner = require("XEntity/XPartner/XPartner")

function XUiPlayerInfoCharacterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.PanelGrade.gameObject:SetActiveEx(false)
    self.ImgInSupport.gameObject:SetActiveEx(false)
    self:AutoAddListener()
end

function XUiPlayerInfoCharacterGrid:Init(playerId)
    self.PlayerId = playerId
end

function XUiPlayerInfoCharacterGrid:AutoAddListener()
    self.BtnCharacter.CallBack = function()
        self:OnBtnCharacter()
    end
end

function XUiPlayerInfoCharacterGrid:OnBtnCharacter()
    XDataCenter.PlayerInfoManager.RequestCharacterInfoData(self.PlayerId, self.Character.Id, function(characterInfo)
        local character = XCharacter.New(characterInfo.CharacterData, true)
        local equipList = {}
        local assignChapterRecords = characterInfo.AssignChapterRecords
        for _, v in pairs(characterInfo.EquipData) do
            local equip = XEquip.New(v)
            table.insert(equipList, equip)
        end
        -- XPartner
        local partner = nil
        if characterInfo.PartnerData then
            partner = XPartner.New(characterInfo.PartnerData.Id, characterInfo.PartnerData.TemplateId, true)
            partner:UpdateData(characterInfo.PartnerData)
            partner:SetIsBelongSelf(characterInfo.IsSelfData)
        end
        -- XLuaUiManager.Open("UiPanelCharPropertyOther", character, equipList, characterInfo.WeaponFashionId, assignChapterRecords, partner, characterInfo.AwarenessSetPositions)

        local data = 
        {
            Character = character,
            EquipList = equipList,
            WeaponFashionId = characterInfo.WeaponFashionId,
            AssignChapterRecords = assignChapterRecords,
            Partner = partner,
            AwarenessSetPositions = characterInfo.AwarenessSetPositions,
        }
        XLuaUiManager.Open("UiPanelCharPropertyOtherV2P7", data)
    end)
end

function XUiPlayerInfoCharacterGrid:UpdateGrid(character, appearanceShowType, assistCharacterDetail)
    if not character then
        XLog.Error("XUiPlayerInfoCharacterGrid:UpdateGrid函数参数错误：参数character不能为空")
        return
    end
    self.Character = character.Data

    if (appearanceShowType == XPlayerInfoConfigs.CharactersAppearanceType.All) then
        -- 展示选项为全部，判断是否拥有该成员
        local isLocked = character.IsLocked

        self.ImgInSupport.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(isLocked)
        self.PanelLevel.gameObject:SetActiveEx(not isLocked)
        self.RImgQuality.gameObject:SetActiveEx(not isLocked)
        self.BtnCharacter.gameObject:SetActiveEx(not isLocked)
        local headInfo = self.Character.CharacterHeadInfo or {}
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.Character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType))

        if not isLocked then
            self.TxtLevel.text = self.Character.Level
            self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.Character.Quality))
            -- 是否为支援角色
            if assistCharacterDetail and self.Character.Id == assistCharacterDetail.Id then
                self.ImgInSupport.gameObject:SetActiveEx(true)
            end
        end
    else
        -- 展示选项为自选，拥有该成员，更新信息
        self.PanelLock.gameObject:SetActiveEx(false)
        self.PanelLevel.gameObject:SetActiveEx(true)
        self.RImgQuality.gameObject:SetActiveEx(true)
        self.BtnCharacter.gameObject:SetActiveEx(true)
        self.ImgInSupport.gameObject:SetActiveEx(false)

        self.TxtLevel.text = self.Character.Level
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.Character.Quality))
        local headInfo = self.Character.CharacterHeadInfo or {}
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.Character.Id, true, headInfo.HeadFashionId, headInfo.HeadFashionType))

        -- 是否为支援角色
        if assistCharacterDetail and self.Character.Id == assistCharacterDetail.Id then
            self.ImgInSupport.gameObject:SetActiveEx(true)
        end
    end
end

return XUiPlayerInfoCharacterGrid