

local XUiEquipGuideSuccess = XLuaUiManager.Register(XLuaUi, "UiEquipGuideSuccess")

function XUiEquipGuideSuccess:OnAwake()
    self:InitCb()
end

function XUiEquipGuideSuccess:OnStart(characterId)
    self.RImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharHalfBodyBigImage(characterId))
    self.TxtName.text = XMVCA.XCharacter:GetCharacterLogName(characterId)
end 

function XUiEquipGuideSuccess:InitCb()
    self.BtnClose.CallBack = function()
        if XLuaUiManager.IsUiShow("UiEquipGuideDetail") 
                or XLuaUiManager.IsUiLoad("UiEquipGuideDetail") then
            XLuaUiManager.Remove("UiEquipGuideDetail")
        end
        self:Close()
    end
end 