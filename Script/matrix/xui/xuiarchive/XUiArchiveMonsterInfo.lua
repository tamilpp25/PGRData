XUiArchiveMonsterInfo = XClass(nil, "XUiArchiveMonsterInfo")

local CSTextManagerGetText = CS.XTextManager.GetText
local EvaluateOneForAll = XArchiveConfigs.EvaluateOnForAll
local InfoShortMax = 4
local InfoLongMax = 5
function XUiArchiveMonsterInfo:Ctor(ui, data, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Data = data
    self.Base = base

    self.InfoContent = {
        self.InfoContent1,
        self.InfoContent2,
        self.InfoContent3,
        self.InfoContent4
    }
    self.DetailContent = {
        self.DetailContent1,
        self.DetailContent2,
        self.DetailContent3,
        self.DetailContent4,
        self.DetailContent5
    }
end

function XUiArchiveMonsterInfo:SelectType(index)
    self:SetMonsterBaseInfoData(index)
    self:SetMonsterShortInfoData(index)
    self:SetMonsterLongInfoData(index)
end

function XUiArchiveMonsterInfo:SetMonsterBaseInfoData(type)
    self.MonsterNameTex.text = (EvaluateOneForAll == XArchiveConfigs.OnForAllState.On) and self.Data:GetName() or self.Data:GetRealName(self.Data:GetNpcId()[type])
    self.KillCount.text = CSTextManagerGetText("ArchiveMonsterKillText", self.Data.Kill[self.Data:GetNpcId()[type]])
    self.ImgIcon:SetRawImage(self.Data:GetIcon())
end

function XUiArchiveMonsterInfo:SetMonsterShortInfoData(type)
    local infoList = XDataCenter.ArchiveManager.GetArchiveMonsterInfoList(self.Data:GetNpcId()[type], XArchiveConfigs.MonsterInfoType.Short)

    for index = 1, InfoShortMax do
        if infoList[index] then
            if not self.MonsterInfo then self.MonsterInfo = {} end

            if not self.MonsterInfo[index] then
                self.MonsterInfo[index] = {}
                self.MonsterInfo[index].Transform = self.InfoContent[index].transform
                self.MonsterInfo[index].GameObject = self.InfoContent[index].gameObject
                XTool.InitUiObject(self.MonsterInfo[index])
            end
            self.MonsterInfo[index].TxtTitle.text = infoList[index]:GetTitle()
            self.MonsterInfo[index].TxtDesc.text = infoList[index]:GetText()
            self.MonsterInfo[index].TxtLock.text = infoList[index]:GetLockDesc()
            self.MonsterInfo[index].UnLock.gameObject:SetActiveEx(not infoList[index]:GetIsLock())
            self.MonsterInfo[index].Lock.gameObject:SetActiveEx(infoList[index]:GetIsLock())
        end
        self.InfoContent[index].gameObject:SetActiveEx(infoList[index] and true or false)
    end
end

function XUiArchiveMonsterInfo:SetMonsterLongInfoData(type)
    local infoList = XDataCenter.ArchiveManager.GetArchiveMonsterInfoList(self.Data:GetNpcId()[type], XArchiveConfigs.MonsterInfoType.Long)

    for index = 1, InfoLongMax do
        if infoList[index] then
            if not self.MonsterDetail then self.MonsterDetail = {} end

            if not self.MonsterDetail[index] then
                self.MonsterDetail[index] = {}
                self.MonsterDetail[index].Transform = self.DetailContent[index].transform
                self.MonsterDetail[index].GameObject = self.DetailContent[index].gameObject
                XTool.InitUiObject(self.MonsterDetail[index])
            end
            self.MonsterDetail[index].TxtTitle.text = infoList[index]:GetTitle()
            self.MonsterDetail[index].TxtDesc.text = infoList[index]:GetText()
            self.MonsterDetail[index].TxtLock.text = infoList[index]:GetLockDesc()
            self.MonsterDetail[index].UnLock.gameObject:SetActiveEx(not infoList[index]:GetIsLock())
            self.MonsterDetail[index].Lock.gameObject:SetActiveEx(infoList[index]:GetIsLock())
        end
        self.DetailContent[index].gameObject:SetActiveEx(infoList[index] and true or false)
    end
end
