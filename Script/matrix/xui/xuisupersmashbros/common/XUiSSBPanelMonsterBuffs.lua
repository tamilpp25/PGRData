--==============
--超限乱斗怪物Buff面板控件
--==============
local XUiSSBPanelMonsterBuffs = XClass(nil, "XUiSSBPanelMonsterBuffs")

function XUiSSBPanelMonsterBuffs:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

--==============
--根据fightEvent列表显示Buff
--fightEventList : 战斗事件列表
--==============
function XUiSSBPanelMonsterBuffs:SetBuff(fightEventList)
    local index = 1
    while true do
        local imgBuff = self["ImgBuff" .. index]
        if not imgBuff then
            break
        end
        local fightEvent = fightEventList[index]
        local isExist = (fightEvent ~= nil) and (fightEvent > 0)
        imgBuff.gameObject:SetActiveEx(isExist)
        if isExist then
            local imgIcon = self["ImgIcon" .. index]
            local details = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEvent)
            if imgIcon and details then
                imgIcon:SetRawImage(details.Icon)
            end
        end
        index = index + 1
    end
end
--==============
--显示面板
--==============
function XUiSSBPanelMonsterBuffs:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--==============
--隐藏面板
--==============
function XUiSSBPanelMonsterBuffs:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBPanelMonsterBuffs