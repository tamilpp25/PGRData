local XUiBabelTowerChallengeSelect = XClass(nil, "XUiBabelTowerChallengeSelect")

function XUiBabelTowerChallengeSelect:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiBabelTowerChallengeSelect:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiBabelTowerChallengeSelect:SetItemData(chooseItem, buffType)
    self.ChooseItem = chooseItem
    self.BuffId = chooseItem.SelectBuffId
    self.BuffType = buffType
    self.BuffConfigs = XFubenBabelTowerConfigs.GetBabelBuffConfigs(self.BuffId)
    self.BuffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(self.BuffId)

    self.TxtDescribe.text = string.format("%s\n%s", self.BuffConfigs.Name, self.BuffConfigs.Desc)
    self:StopFx()
end

function XUiBabelTowerChallengeSelect:PlayFx()
    if self.ImgFx then
        if self.ImgFx.gameObject.activeSelf then
            self.ImgFx.gameObject:SetActiveEx(false)
        end

        self.ImgFx.gameObject:SetActiveEx(true)
    end
end

function XUiBabelTowerChallengeSelect:StopFx()
    if self.ImgFx then
        self.ImgFx.gameObject:SetActiveEx(false)
    end
end

function XUiBabelTowerChallengeSelect:GetBuffDescriptionHeight()
    return self.TxtDescribe.preferredHeight
end


return XUiBabelTowerChallengeSelect