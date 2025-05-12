local XUiDlcMultiPlayerTitleCommon = require(
"XUi/XUiDlcMultiPlayer/XUiDlcMultiPlayerCommon/XUiDlcMultiPlayerTitleCommon")

---@class XUiDlcMultiPlayerLoadingItem : XUiNode
---@field RImgHead UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtNum UnityEngine.UI.Text
---@field TitleGrid UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
---@field ImgSkill UnityEngine.UI.Image
---@field TxtSkillName UnityEngine.UI.Text
---@field ImgCamp UnityEngine.UI.RawImage
---@field ImgProgress UnityEngine.UI.Image
local XUiDlcMultiPlayerLoadingItem = XClass(XUiNode, "XUiDlcMultiPlayerLoadingItem")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp
-- region 生命周期

function XUiDlcMultiPlayerLoadingItem:OnStart(playerData)
    self._IsFinish = false
    self._TitleGrid = nil

    self:_Init(playerData)
end

-- endregion

function XUiDlcMultiPlayerLoadingItem:RefreshProgress(progress)
    if progress < 100 then
        self.TxtNum.text = progress .. "%"
        self.ImgProgress.fillAmount = progress / 100.0
    else
        if not self._IsFinish then
            self.TxtNum.text = "100%"
            self.ImgProgress.fillAmount = 1.0
            self.Parent:RefreshFinishCount()
            self._IsFinish = true
        end
    end
end

-- region 私有方法

---@param playerData XDlcPlayerData
function XUiDlcMultiPlayerLoadingItem:_Init(playerData)
    local characterId = playerData:GetCharacterId()
    local icon = self._Control:GetCharacterCuteHeadIconByCharacterId(characterId)
    ---@type XDlcMultiMouseHunterPlayerData
    local customData = playerData:GetCustomData()
    local camp = playerData:GetCamp()

    self.TxtName.text = playerData:GetNickname()
    self.TxtNum.text = "0%"
    self.ImgProgress.fillAmount = 0
    self.TxtNum.gameObject:SetActiveEx(true)
    self.ImgProgress.gameObject:SetActiveEx(true)
    self.RImgHead:SetRawImage(icon)

    if camp == CampEnum.Cat then
        local skillConfig = self._Control:GetDlcMultiplayerSkillConfigById(playerData:GetCatSkillId())
        self.TxtSkillName.text = skillConfig.Name
        self.ImgSkill:SetRawImage(skillConfig.Icon)
        self.ImgCamp:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("LoadingCatIcon").Values[1])
    elseif camp == CampEnum.Mouse then
        local skillConfig = self._Control:GetDlcMultiplayerSkillConfigById(playerData:GetMouseSkillId())
        self.TxtSkillName.text = skillConfig.Name
        self.ImgSkill:SetRawImage(skillConfig.Icon)
        self.ImgCamp:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("LoadingMouseIcon").Values[1])
    end

    if customData and not customData:IsClear() then
        local titleId = customData:GetTitleId()

        if XTool.IsNumberValid(titleId) then
            self._TitleGrid = XUiDlcMultiPlayerTitleCommon.New(self.TitleGrid, self, titleId)
        else
            self.TitleGrid.gameObject:SetActiveEx(false)
        end
    else
        self.TitleGrid.gameObject:SetActiveEx(false)
    end
end

-- endregion

return XUiDlcMultiPlayerLoadingItem