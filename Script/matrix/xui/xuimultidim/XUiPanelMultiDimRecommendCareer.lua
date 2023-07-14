local XUiPanelMultiDimRecommendCareer = XClass(nil, "XUiPanelMultiDimRecommendCareer")

---@param transform UnityEngine.RectTransform
function XUiPanelMultiDimRecommendCareer:Ctor(transform)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.IconList = {}
    XTool.InitUiObject(self)
end

function XUiPanelMultiDimRecommendCareer:Refresh(stageId)
    self.StageId = stageId
    local careerRecommendList = XMultiDimConfig.GetMultiDimRecommendCareerList(self.StageId)
    for i, careerId in pairs(careerRecommendList) do
        local icon = XMultiDimConfig.GetMultiDimCareerIcon(careerId)
        if not self.IconList[i] then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.RImgIcon,self.PanelType)
            self.IconList[i] = obj
        end
        self.IconList[i]:SetRawImage(icon)
    end
    self.RImgIcon.gameObject:SetActiveEx(false)
end

function XUiPanelMultiDimRecommendCareer:SetActive(isShow)
    self.GameObject:SetActiveEx(isShow)
end

return XUiPanelMultiDimRecommendCareer