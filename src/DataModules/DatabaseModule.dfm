object DMDatabase: TDMDatabase
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 480
  Width = 640
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=MSSQL')
    Transaction = FDTransaction
    LoginPrompt = False
    Left = 56
    Top = 32
  end
  object FDPhysMSSQLDriverLink: TFDPhysMSSQLDriverLink
    Left = 56
    Top = 96
  end
  object FDPhysMySQLDriverLink: TFDPhysMySQLDriverLink
    Left = 56
    Top = 160
  end
  object FDPhysPgDriverLink: TFDPhysPgDriverLink
    Left = 56
    Top = 224
  end
  object FDPhysOracleDriverLink: TFDPhysOracleDriverLink
    Left = 56
    Top = 288
  end
  object FDPhysSQLiteDriverLink: TFDPhysSQLiteDriverLink
    Left = 56
    Top = 352
  end
  object FDTransaction: TFDTransaction
    Connection = FDConnection
    Left = 184
    Top = 32
  end
  object qryGeneral: TFDQuery
    Connection = FDConnection
    Transaction = FDTransaction
    Left = 312
    Top = 32
  end
  object qryProducts: TFDQuery
    Connection = FDConnection
    Transaction = FDTransaction
    Left = 312
    Top = 96
  end
  object qrySales: TFDQuery
    Connection = FDConnection
    Transaction = FDTransaction
    Left = 312
    Top = 160
  end
  object qryUsers: TFDQuery
    Connection = FDConnection
    Transaction = FDTransaction
    Left = 312
    Top = 224
  end
  object qryReports: TFDQuery
    Connection = FDConnection
    Transaction = FDTransaction
    Left = 312
    Top = 288
  end
end
