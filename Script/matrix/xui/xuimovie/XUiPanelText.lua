---@class XUiPanelText
local XUiPanelText = XClass(XUiNode, "XUiPanelText")

function XUiPanelText:OnStart()
    self.GridText1.gameObject:SetActiveEx(false)
    self.GridText2.gameObject:SetActiveEx(false)
    self.GridText3.gameObject:SetActiveEx(false)
    self.TextDic = {}
end

-- 显示文本
function XUiPanelText:AppearText(layer, id, content, posX, posY, rotation, isAnim)
    local text = self.TextDic[id]
    if not text then
        text = XUiHelper.Instantiate(self["GridText"..layer], self.TextList.transform)
        self.TextDic[id] = text
    end
    text.gameObject:SetActiveEx(true)
    text.text = XUiHelper.ConvertLineBreakSymbol(content)
    local Vector3 = CS.UnityEngine.Vector3
    text.transform.localPosition = Vector3(posX, posY, 0)
    text.transform.eulerAngles = Vector3(0, 0, rotation)
    if isAnim then
        local anim = XUiHelper.TryGetComponent(text.transform, "Ainmation/GridTextEnable")
        anim:PlayTimelineAnimation()
    else
        text.transform:GetComponent("CanvasGroup").alpha = 1
    end
    return text
end

-- 隐藏指定id的文本
function XUiPanelText:DisAppearText(id, isAnim)
    local text = self.TextDic[id]
    if isAnim then
        local anim = XUiHelper.TryGetComponent(text.transform, "Ainmation/GridTextDisable")
        anim:PlayTimelineAnimation(function()
            text.gameObject:SetActiveEx(false)
        end)
    else
        text.gameObject:SetActiveEx(false)
    end
end

-- 隐藏所有文本
function XUiPanelText:DisAppearAllText()
    for _, tempText in pairs(self.TextDic) do
        local text = tempText
        if text.gameObject.activeSelf then
            --local anim = XUiHelper.TryGetComponent(text.transform, "Ainmation/GridTextDisable")
            --anim:PlayTimelineAnimation(function()
                text.gameObject:SetActiveEx(false)
            --end)
        end
    end
end

return XUiPanelText