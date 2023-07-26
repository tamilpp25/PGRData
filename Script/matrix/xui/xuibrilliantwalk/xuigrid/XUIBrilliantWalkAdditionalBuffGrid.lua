--被动浏览界面的grid
local XUIBrilliantWalkAdditionalBuffGrid = XClass(nil, "XUIBrilliantWalkAdditionalBuffGrid")

function XUIBrilliantWalkAdditionalBuffGrid:Ctor(perfabObject, rootUi)
    self.GameObject = perfabObject.gameObject
    self.Transform = perfabObject.transform
    XTool.InitUiObject(self)
end

function XUIBrilliantWalkAdditionalBuffGrid:UpdateView(config)
    self.TxtName.text = config.Name
    self.TxtDesc.text = config.Desc
    if config.Icon then
        self.RImgIcon:SetRawImage(config.Icon)
    end
end


return XUIBrilliantWalkAdditionalBuffGrid