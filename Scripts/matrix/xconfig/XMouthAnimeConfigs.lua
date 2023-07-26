XMouthAnimeConfigs = XMouthAnimeConfigs or {}

local TABLE_MOUTHDATA = "Client/MouthData/MouthData.tab"
local MouthDataCfg = {}
local MouthDataDic = {}

XMouthAnimeConfigs.FrameUnit = 100

function XMouthAnimeConfigs.Init()
    MouthDataCfg = XTableManager.ReadByIntKey(TABLE_MOUTHDATA, XTable.XTableMouthData, "Id")
    XMouthAnimeConfigs.CreateMouthDataDic()
end

function XMouthAnimeConfigs.GetMouthDataCfg()
    return MouthDataCfg
end

function XMouthAnimeConfigs.CreateMouthDataDic()
    local count = {}
    for _,cfg in pairs(MouthDataCfg) do
        if not MouthDataDic[cfg.CvId] then
            MouthDataDic[cfg.CvId] = {}
            count[cfg.CvId] = 1
        end

        local millisecond = XMouthAnimeConfigs.FrameUnit * count[cfg.CvId]
        if cfg.Msec > millisecond then
            count[cfg.CvId] = count[cfg.CvId] + 1
        end
        
        MouthDataDic[cfg.CvId][millisecond] = MouthDataDic[cfg.CvId][millisecond] or {}
        table.insert(MouthDataDic[cfg.CvId][millisecond],cfg)
    end
end

function XMouthAnimeConfigs.GetMouthDataDic()
    return MouthDataDic
end