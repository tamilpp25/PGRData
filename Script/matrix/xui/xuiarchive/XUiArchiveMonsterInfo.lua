local XUiArchiveMonsterInfo = XClass(XUiNode, "XUiArchiveMonsterInfo")

local CSTextManagerGetText = CS.XTextManager.GetText
local EvaluateOneForAll = nil
local InfoShortMax = 4
local InfoLongMax = 5

function XUiArchiveMonsterInfo:OnStart(data, base)
    EvaluateOneForAll=self._Control:GetEvaluateOnForAll()
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

function XUiArchiveMonsterInfo:SelectType(npcId)
    self:Open()
    self:SetMonsterBaseInfoData(npcId)
    self:SetMonsterShortInfoData(npcId)
    self:SetMonsterLongInfoData(npcId)
end

function XUiArchiveMonsterInfo:SetMonsterBaseInfoData(npcId)
    self.MonsterNameTex.text = (EvaluateOneForAll == XEnumConst.Archive.OnForAllState.On) and self.Data:GetName() or self.Data:GetRealName(npcId)
    self.KillCount.text = CSTextManagerGetText("ArchiveMonsterKillText", self.Data.Kill[npcId])
    self.ImgIcon:SetRawImage(self.Data:GetIcon())
end

function XUiArchiveMonsterInfo:SetMonsterShortInfoData(npcId)
    local infoList = self._Control:GetArchiveMonsterInfoList(npcId, XEnumConst.Archive.MonsterInfoType.Short)

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

function XUiArchiveMonsterInfo:SetMonsterLongInfoData(npcId)
    local infoList = self._Control:GetArchiveMonsterInfoList(npcId, XEnumConst.Archive.MonsterInfoType.Long)

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


return XUiArchiveMonsterInfo