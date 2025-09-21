<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "satisfisleri".
 *
 * @property int $FisId
 * @property string $FisNo
 * @property string $Fistarihi
 * @property int|null $MusteriId
 * @property float $Toplamtutar
 * @property string|null $OdemeTuru
 * @property float|null $NakitOdeme
 * @property float|null $KartOdeme
 * @property string|null $status
 * @property int $PosId
 * @property int|null $SyncStatus
 * @property string|null $LastSyncTime
 *
 * @property Satissatirlari[] $satissatirlaris
 */
class Satisfisleri extends \yii\db\ActiveRecord
{
    public $unvan;
    public $total_amount;


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satisfisleri';
    }

    public function attributes()
    {
        return array_merge(parent::attributes(), ['unvan', 'total_amount']);
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['MusteriId', 'OdemeTuru', 'NakitOdeme', 'KartOdeme', 'status', 'LastSyncTime', 'CekOdeme', 'CekTarih', 'CekNo'], 'default', 'value' => null],
            [['SyncStatus'], 'default', 'value' => 0],
            [['FisNo', 'Fistarihi', 'Toplamtutar'], 'required'],
            [['Fistarihi', 'LastSyncTime', 'CekTarih','deliverydate'], 'safe'],
            [[ 'SyncStatus', 'diakey', 'cash_session_id', 'kaynak'], 'integer'],
            [['Toplamtutar', 'NakitOdeme', 'KartOdeme', 'CekOdeme','Iskontotutari'], 'number'],
            [['FisNo', 'CekNo'], 'string', 'max' => 50],
            [['OdemeTuru','satispersoneli','tillname'], 'string', 'max' => 50],
            [['status','MusteriId'], 'string', 'max' => 20],
            [['comment'], 'string', 'max' => 255],
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
            'FisNo' => 'Receipt No',
            'Fistarihi' => 'Receipt Date',
            'MusteriId' => 'Customer Code',
            'Toplamtutar' => 'Total Amount',
            'OdemeTuru' => 'Payment Type',
            'NakitOdeme' => 'Cash Amount',
            'KartOdeme' => 'Credit Cart Amount',
            'status' => 'Status',
            'SyncStatus' => 'Sync Status',
            'LastSyncTime' => 'Last Sync Time',
            'CekNo' => 'Check No',
            'CekTarih' => 'Check Date',
            'CekOdeme' => 'Check Amount',
            'cash_session_id' => 'Cash Session ID',
            'kaynak' => 'Source',
        ];
    }

    public function getKasano(){
        $parts = explode('-', $this->FisNo);
        $kasano = (int)$parts[0];
        return $kasano;
    }

    public function getKasa(){
        return $this->hasOne(CashRegisters::class, ['id' =>$this->kasano]);

    }
    /**
     * Gets query for [[Satissatirlaris]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSatissatirlari()
    {
        return $this->hasMany(Satissatirlari::class, ['FisNo' => 'FisNo']);
    }

    public function getCarihareketler()
    {
        return $this->hasMany(CariHareketler::class, ['FisId' => 'FisId']);
    }
    public function getKalantutar()
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

    public function getSatispersoneli(){
        return $this->hasOne(Satiscilar::class, ['kodu' =>$this->satispersoneli]);

    }
}
