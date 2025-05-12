local XUiArchiveMonsterSetting = XClass(XUiNode, "XUiArchiveMonsterSetting")

local SettingMax = 5
local StoryMax = 5

function XUiArchiveMonsterSetting:OnStart(data, base)
    self.Data = data
    self.Base = base

    self.SettingContent = {
        self.SettingContent1,
        self.SettingContent2,
        self.SettingContent3,
        self.SettingContent4,
        self.SettingContent5
    }
    self.StoryContent = {
        self.StoryContent1,
        self.StoryContent2,
        self.StoryContent3,
        self.StoryContent4,
        self.StoryContent5
    }
end

function XUiArchiveMonsterSetting:SelectType(npcId)
    self:Open()
    self:SetMonsterSettingData(npcId)
    self:SetMonsterStoryData(npcId)
end

function XUiArchiveMonsterSetting:SetMonsterSettingData(npcId)
    local settingList = self._Control:GetArchiveMonsterSettingList(npcId, XEnumConst.Archive.MonsterSettingType.Setting)

    for index = 1, SettingMax do
        if settingList[index] then
            if not self.SettingItem then self.SettingItem = {} end

            if not self.SettingItem[index] then
                self.SettingItem[index] = {}
                self.SettingItem[index].Transform = self.SettingContent[index].transform
                self.SettingItem[index].GameObject = self.SettingContent[index].gameObject
                XTool.InitUiObject(self.SettingItem[index])
            end
            self.SettingItem[index].TxtTitle.text = settingList[index]:GetTitle()
            self.SettingItem[index].TxtDesc.text = settingList[index]:GetText()
            self.SettingItem[index].TxtLock.text = settingList[index]:GetLockDesc()
            self.SettingItem[index].UnLock.gameObject:SetActiveEx(not settingList[index]:GetIsLock())
            self.SettingItem[index].Lock.gameObject:SetActiveEx(settingList[index]:GetIsLock())
        end
        self.SettingContent[index].gameObject:SetActiveEx(settingList[index] and true or false)
    end
end

function XUiArchiveMonsterSetting:SetMonsterStoryData(npcId)
    local settingList = self._Control:GetArchiveMonsterSettingList(npcId, XEnumConst.Archive.MonsterSettingType.Story)

    for index = 1, StoryMax do
        if settingList[index] then
            if not self.StoryItem then self.StoryItem = {} end

            if not self.StoryItem[index] then
                self.StoryItem[index] = {}
                self.StoryItem[index].Transform = self.StoryContent[index].transform
                self.StoryItem[index].GameObject = self.StoryContent[index].gameObject
                XTool.InitUiObject(self.StoryItem[index])
            end
            self.StoryItem[index].TxtTitle.text = settingList[index]:GetTitle()
            self.StoryItem[index].TxtDesc.text = settingList[index]:GetText()
            self.StoryItem[index].TxtLock.text = settingList[index]:GetLockDesc()
            self.StoryItem[index].UnLock.gameObject:SetActiveEx(not settingList[index]:GetIsLock())
            self.StoryItem[index].Lock.gameObject:SetActiveEx(settingList[index]:GetIsLock())
        end
        self.StoryContent[index].gameObject:SetActiveEx(settingList[index] and true or false)
    end
end



return XUiArchiveMonsterSetting