---@class XUiDlcCasualGameLoadingItem : XUiNode
---@field RImgHead UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field ImgBar UnityEngine.UI.Image
---@field TxtPercent UnityEngine.UI.Text
---@field _Control XDlcCasualControl
local XUiDlcCasualGameLoadingItem = XClass(XUiNode, "XUiDlcCasualGameLoadingItem")

---@param data XDlcPlayerData
function XUiDlcCasualGameLoadingItem:OnStart(data)
    self:_Init(data)
end

---@param data XDlcPlayerData
function XUiDlcCasualGameLoadingItem:_Init(data)
    local characterId = data:GetCharacterId(1)
    local character = self._Control:GetCharacterCuteById(characterId)
    local icon = character:GetRoundHeadImage()
    
    self.TxtName.text = data:GetNickname()
    self.TxtPercent.text = "0%"
    self.ImgBar.fillAmount = 0
    self.RImgHead:SetRawImage(icon)
end

function XUiDlcCasualGameLoadingItem:RefreshProgress(progress)
    if progress < 100 then
        self.TxtPercent.text = progress .. "%"
        self.ImgBar.fillAmount = progress / 100
    else
        self.TxtPercent.text = XUiHelper.GetText("DlcCasualLoadingComplete")
        self.ImgBar.fillAmount = 1
    end
end

return XUiDlcCasualGameLoadingItem