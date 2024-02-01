-- 角色筛选界面的的标签组
local XUiGridFilterTagGroup = XClass(nil, "XUiGridFilterTagGroup")

function XUiGridFilterTagGroup:Ctor(ui, rootUi, groupId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.CharacterType = rootUi.CharacterType
    self.GroupId = groupId

    self.TagItem = {}

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiGridFilterTagGroup:InitComponent()
    self.BtnFilterTagGrid.gameObject:SetActiveEx(false)
end

function XUiGridFilterTagGroup:Refresh()
    self.TxtGroupName.text = XRoomCharFilterTipsConfigs.GetFilterTagGroupName(self.GroupId)
    local tags = XRoomCharFilterTipsConfigs.GetFilterTagGroupTags(self.GroupId)
    for _, tagId in pairs(tags) do
        local tabCharType = XRoomCharFilterTipsConfigs.GetFilterTagCharType(tagId)
        if tabCharType == self.CharacterType or tabCharType == 0 or self.CharacterType == XEnumConst.CHARACTER.CharacterType.Robot then
            -- 筛选标签的角色类型为当前的角色类型或通用，则生成
            local btnTag = CS.UnityEngine.Object.Instantiate(self.BtnFilterTagGrid)
            btnTag.transform:SetParent(self.PanelTags, false)
            btnTag.gameObject:SetActiveEx(true)
            btnTag:SetName(XRoomCharFilterTipsConfigs.GetFilterTagName(tagId))
            btnTag.CallBack = function()
                self:OnTagClick(tagId)
            end

            if XDataCenter.RoomCharFilterTipsManager.CheckFilterTagIsSelect(self.GroupId, tagId, self.CharacterType) then
                btnTag:SetButtonState(XUiButtonState.Select)
            end

            self.TagItem[tagId] = btnTag
        end
    end
end

---
--- 清除所有选择的标签
function XUiGridFilterTagGroup:ClearAllSelectTag()
    for tagId, tag in pairs(self.TagItem) do
        if tag.ButtonState == CS.UiButtonState.Select then
            tag:SetButtonState(XUiButtonState.Normal)
            self:OnTagClick(tagId)
        end
    end
end

function XUiGridFilterTagGroup:OnTagClick(tagId)
    XDataCenter.RoomCharFilterTipsManager.SetSelectFilterTag(self.GroupId, tagId,
            self.TagItem[tagId].ButtonState == CS.UiButtonState.Select)
end

return XUiGridFilterTagGroup