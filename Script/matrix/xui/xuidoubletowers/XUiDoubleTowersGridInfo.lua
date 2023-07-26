---@class XUiDoubleTowersGridInfo
local XUiDoubleTowersGridInfo = XClass(nil, "XUiDoubleTowersGridInfo")
function XUiDoubleTowersGridInfo:Ctor(rootUi, ui)
    if not ui then
        ui = rootUi
    else
        self.RootUi = rootUi
    end
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiDoubleTowersGridInfo:Refresh(infoId)
    -- 左上角 飞行/地面/剧毒
    self.TxtDesc.text = XDoubleTowersConfigs.GetEnemyInfoTypeDesc(infoId)

    -- 左下角 波数
    self.TxtCount.text = XDoubleTowersConfigs.GetEnemyInfoRoundDesc(infoId)

    -- 图标
    self.RImgIcon:SetRawImage(XDoubleTowersConfigs.GetEnemyInfoImg(infoId))
end

--todo instea of UiObject
function XUiDoubleTowersGridInfo:InitUi()
    self.TxtDesc = XUiHelper.TryGetComponent(self.Transform, "TxtCount (1)", "Text")
    self.TxtCount = XUiHelper.TryGetComponent(self.Transform, "TxtCount", "Text")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgIcon", "RawImage")
end

return XUiDoubleTowersGridInfo
