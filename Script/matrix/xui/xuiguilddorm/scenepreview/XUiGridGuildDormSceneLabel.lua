local XUiGridGuildDormSceneLabel = XClass(nil,"XUiGridGuildDormSceneLabel")

function XUiGridGuildDormSceneLabel:Ctor(transform,clickCallBack)
    self.Transform = transform
    self.GameObject = transform.gameObject
    XTool.InitUiObject(self)
    self.ClickCallBack = clickCallBack
    self.Labels = {}
end

function XUiGridGuildDormSceneLabel:SetText(labelStr)
    local labelList = string.Split(labelStr, "|")
    for _, label in pairs(self.Labels) do
        label.gameObject:SetActiveEx(false)
    end

    for i, labelIdStr in ipairs(labelList) do
        local config = XGuildDormConfig.GetLabelConfigById(tonumber(labelIdStr))
        
        if not self.Labels[i] then
            self.Labels[i] = CS.UnityEngine.GameObject.Instantiate(self.BtnLabel, self.Transform)
            self.Labels[i].CallBack = function()
                if self.ClickCallBack then
                    self.ClickCallBack()
                end
            end
        end
        local textComponent = self.Labels[i].transform:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))
        local image = self.Labels[i].transform:GetComponent(typeof(CS.UnityEngine.UI.Image))
        textComponent.text = config.Name
        image.color = XUiHelper.Hexcolor2Color(config.BgColor)

        self.Labels[i].gameObject:SetActiveEx(true)
    end
    self.BtnLabel.gameObject:SetActiveEx(false)
end

function XUiGridGuildDormSceneLabel:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

return XUiGridGuildDormSceneLabel