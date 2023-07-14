--组合小游戏背包动态列表组件
local XUiComposeGameBagGrid = XClass(nil, "XUiComposeGameBagGrid")
--================
--构造函数(动态列表组件初始化不在这里做)
--================
function XUiComposeGameBagGrid:Ctor()

end
--================
--初始化
--@param ui:组件的对象
--================
function XUiComposeGameBagGrid:Init(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PanelEffectCompose.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
    self:InitPanelStar()
end
--================
--初始化星数面板
--================
function XUiComposeGameBagGrid:InitPanelStar()
    local PanelStar = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGameStarPanelLevel")
    self.Star = PanelStar.New(self.PanelLevel)
end
--================
--更新新内容数据
--@param gridInfo:内容数据
--================
function XUiComposeGameBagGrid:RefreshData(gridInfo)
    if not gridInfo then
        return
    end
    self.GridInfo = gridInfo
    self.Item = self.GridInfo:GetItem()
    self:SetIsEmpty()
    self:SetDisplayItem()
    self:SetNewItemEffect()
end
--================
--设置是否空背包
--================
function XUiComposeGameBagGrid:SetIsEmpty()
    local isEmpty = self.Item:CheckIsEmpty()
    self.Disable.gameObject:SetActiveEx(isEmpty)
    self.Normal.gameObject:SetActiveEx(not isEmpty)
end
--================
--设置展示道具
--================
function XUiComposeGameBagGrid:SetDisplayItem()
    if not self.Item or (self.Item:CheckIsEmpty()) then return end
    self.TxtName.text = self.Item:GetName()
    self.RImgIcon:SetRawImage(self.Item:GetSmallIcon())
    self.Star:ShowStar(self.Item:GetStar())
end
--================
--设置新道具特效
--================
function XUiComposeGameBagGrid:SetNewItemEffect()
    local noShowEffect = true
    local finalItem = true
    if not self.Item or self.Item:CheckIsEmpty() then
        noShowEffect = true
        finalItem = false
    else
        local isNew = XDataCenter.ComposeGameManager.GetItemIsNew(self.Item:GetGameId(), self.Item:GetId())
        noShowEffect = not isNew
        finalItem = self.Item:GetIsFinalItem()
    end
    if noShowEffect then
        self.PanelEffectCompose.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
    else
        self.PanelEffectCompose.gameObject:SetActiveEx(finalItem)
        self.PanelEffect.gameObject:SetActiveEx(not finalItem) 
    end
end
--================
--被点击时事件
--================
function XUiComposeGameBagGrid:OnClick()
    if not self.Item or (self.Item:CheckIsEmpty()) then return end
    XLuaUiManager.Open("UiTip", self.Item:GetTempItemData())
end

return XUiComposeGameBagGrid