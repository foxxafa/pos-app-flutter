<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "iadefisleri".
 *
 * @property int $FisId
 * @property string $FisNo
 * @property string $Fistarihi
 * @property string|null $MusteriId
 * @property float $Toplamtutar
 * @property string|null $OdemeTuru
 * @property float|null $NakitOdeme
 * @property float|null $KartOdeme
 * @property string|null $status
 * @property int|null $SyncStatus
 * @property string|null $LastSyncTime
 * @property int|null $diakey
 * @property string|null $tur
 */
class Iadefisleri extends \yii\db\ActiveRecord
{

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'iadefisleri';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['OdemeTuru', 'NakitOdeme', 'KartOdeme', 'status', 'LastSyncTime', 'diakey'], 'default', 'value' => null],
            [['SyncStatus'], 'default', 'value' => 0],
            [['FisNo', 'Fistarihi', 'Toplamtutar'], 'required'],
            [['Fistarihi', 'LastSyncTime'], 'safe'],
            [['SyncStatus', 'diakey' , 'payed', 'cash_session_id'], 'integer'],
            [['Toplamtutar', 'NakitOdeme', 'KartOdeme'], 'number'],
            [['FisNo'], 'string', 'max' => 40],
            [['MusteriId'], 'string', 'max' => 20],
            [['iadenedeni', 'satispersoneli', 'tillname'], 'string', 'max' => 45],
            [['OdemeTuru'], 'string', 'max' => 50],
            [['status'], 'string', 'max' => 20],
            [['tur'], 'string', 'max' => 15],
            [['aciklama'], 'string', 'max' => 255],
            [['FisNo'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'FisId' => 'Receipt ID',
            'FisNo' => 'Receipt Number',
            'Fistarihi' => 'Receipt Date',
            'MusteriId' => 'Customer Code',
            'Toplamtutar' => 'Total Amount',
            'OdemeTuru' => 'Payment Type',
            'NakitOdeme' => 'Cash Payment',
            'KartOdeme' => 'Card Payment',
            'status' => 'Status',
            'SyncStatus' => 'Sync Status',
            'LastSyncTime' => 'Last Sync Time',
            'diakey' => 'Diakey',
            'payed' => 'Payment Status',
            'cash_session_id' => 'Cash Session ID',
            'tur' => 'Type',
            'aciklama' => 'Description',
            'iadenedeni' => 'Reason for Return',
            'satispersoneli' => 'Sales Staff',
            'tillname' => 'Till Name',
        ];
    }
    public function getSatissatirlari()
    {
        return $this->hasMany(Iadesatirlari::class, ['FisNo' => 'FisNo']);
    }
    public function getCarihareketler()
    {
        return $this->hasMany(CariHareketler::class, ['FisId' => 'FisId']);
    }
    public function getKalanatutar()
    {
        return $this->Toplamtutar - $this->getCarihareketler()->sum('Tutar');
    }
    public function getOdenen()
    {
        return $this->getCarihareketler()->sum('Tutar');
    }
    public function getMusteri()
    {
        return $this->hasOne(Musteriler::class, ['Kod' => 'MusteriId']);
    }
}
