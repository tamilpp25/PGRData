--工会boss技能grid组件
local XUiGuildBossStyleGrid = XClass(nil, "XUiGuildBossStyleGrid")

function XUiGuildBossStyleGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGuildBossStyleGrid:Init(styleConfig, isSelect)
    self.Config = styleConfig
    self:SetCurMask(isSelect)
    self.Btn01:SetRawImage(styleConfig.Bg)
    self.Btn01.CallBack = function () self.RootUi:OpenStyleDetailWithPlayScroll((styleConfig.Id)) end -- 点击格子滑动打开详情
end

function XUiGuildBossStyleGrid:SetCurMask(flag)
    self.CurMark.gameObject:SetActiveEx(flag)
end

return XUiGuildBossStyleGrid