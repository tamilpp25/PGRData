local XUiDormFoundryDetailItem = XClass(nil, "XUiDormFoundryDetailItem")

function XUiDormFoundryDetailItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiDormFoundryDetailItem:OnRefresh(itemData)
    if not itemData then
        return
    end

    local iconpath = itemData.CurIconpath
    if iconpath and self.CurIconpath ~= iconpath then
        self.CurIconpath = iconpath
        self.UiRoot:SetUiSprite(self.ImgIcon, iconpath)
    end

    self.MoodValue.text = string.format("-%s", math.floor(itemData.DaiGongData.Mood / 100))
end

function XUiDormFoundryDetailItem:Init(parent, uiRoot)
    self.Parent = parent
    self.UiRoot = uiRoot
end
return XUiDormFoundryDetailItem