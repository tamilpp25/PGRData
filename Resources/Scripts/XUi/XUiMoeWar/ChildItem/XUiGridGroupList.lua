local XUiGridGroupList = XClass(nil, "XUiGridGroupList")
local XUiGridPairGroup = require("XUi/XUiMoeWar/ChildItem/XUiGridPairGroup")
local tableInsert = table.insert

function XUiGridGroupList:Ctor(ui, index)
    ---@type UnityEngine.GameObject
    self.GameObject = ui
    self.Transform = self.GameObject.transform
    self.GroupId = index
    self.GroupConfig = XMoeWarConfig.GetInitPairsByGroupId(index)
    XTool.InitUiObject(self)
    local activityInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    self.TxtFirstTitle.text = activityInfo.GroupName[index]
    self.TxtSecondTitle.text = activityInfo.GroupSecondName[index]
    self:InitPairList()
end

function XUiGridGroupList:InitPairList()
    self.PairList = {}
    for i = 1, #self.GroupConfig do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnGroup, self.GroupList)
        local gird = XUiGridPairGroup.New(obj, self.GroupConfig[i], i)
        tableInsert(self.PairList, gird)
    end
    self.BtnGroup.gameObject:SetActiveEx(false)
end

return XUiGridGroupList