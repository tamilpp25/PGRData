local XUiAwarenessOccupyPosTips = XLuaUiManager.Register(XLuaUi, "UiAwarenessOccupyPosTips")
local Color = 
{
    Active = "0F70BC",
    UnActive = "656565"
}

function XUiAwarenessOccupyPosTips:OnAwake()
    self:InitButton()
end

function XUiAwarenessOccupyPosTips:OnStart(equipId, pos)
    self.EquipId = equipId
    self.Pos = pos
end

function XUiAwarenessOccupyPosTips:InitButton()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnOccupy, self.OnBtnOccupyClick)
end

function XUiAwarenessOccupyPosTips:OnEnable()
    local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(self.EquipId)
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite)
    local isOccupy = data:IsOccupy()
    local color = isOccupy and Color.Active or Color.UnActive
    self.ChapterData = data

    -- 标签文本，意识位，颜色
    self.TxtTitle1.text = CS.XTextManager.GetText("AwarenessFight")
    self.ImgLabel.color = XUiHelper.Hexcolor2Color(color)
    self.TxtTitleMarkUp.color = XUiHelper.Hexcolor2Color(color)
    self.TxtNumber.text = CS.XTextManager.GetText("AwarenessTfPos", data:GetChapterOrder())
    self.TxtPos.text = "0"..self.Pos
    
    -- 驻守按钮
    self.OccupyCharacter.gameObject:SetActiveEx(isOccupy)
    if isOccupy then
        self.OccupyRoleIcon:SetRawImage(data:GetOccupyCharacterIcon())
    end
    
    -- 共鸣绑定角色
    local characterId = XMVCA.XEquip:GetResonanceBindCharacterId(self.EquipId, self.Pos)
    if XTool.IsNumberValid(characterId) then
        self.StandIcon:SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characterId))
    end

    -- 伤害加成
    self.TxtTitleMarkUp.text = XMVCA.XEquip:GetEquipAwarenessOccupyHarmDesc(self.EquipId)
end

function XUiAwarenessOccupyPosTips:OnBtnOccupyClick()
    self:Close()
    if self.ChapterData:CanAssign() then
        XLuaUiManager.Open("UiAwarenessOccupy", self.ChapterData:GetId())
    else
        XDataCenter.FubenAwarenessManager.OpenUi(function ()
            XLuaUiManager.Open("UiAwarenessMainDetail", self.ChapterData:GetId())
        end)
    end
end
