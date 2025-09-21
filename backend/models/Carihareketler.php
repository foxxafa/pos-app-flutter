<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "carihareketler".
 *
 * @property int $HareketId
 * @property string|null $HareketTuru
 * @property string|null $HareketTarihi
 * @property string|null $CariId
 * @property string|null $FisId
 * @property float|null $Tutar
 * @property string|null $ParaBirimi
 * @property string|null $Aciklama
 * @property string|null $OdemeYontemi
 * @property int|null $cash_session_id
 * @property string|null $OlusturulmaTarihi
 * @property string|null $GuncellenmeTarihi
 * @property string|null $carikod
 * @property string|null $IslemYapan
 * @property string|null $cek_no
 * @property string|null $vadetarihi
 */
class CariHareketler extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'carihareketler';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['HareketTarihi', 'OlusturulmaTarihi', 'GuncellenmeTarihi', 'vadetarihi'], 'safe'],
            [['Tutar'], 'number'],
            [['cash_session_id'], 'integer'],
            [['FisId', 'Aciklama'], 'string'],
            [['HareketTuru', 'OdemeYontemi'], 'string', 'max' => 50],
            [['CariId', 'carikod'], 'string', 'max' => 15],
            [['ParaBirimi'], 'string', 'max' => 10],
            [['IslemYapan'], 'string', 'max' => 100],
            [['cek_no'], 'string', 'max' => 45],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'HareketId' => 'Transaction ID',
            'HareketTuru' => 'Transaction Type',
            'HareketTarihi' => 'Transaction Date',
            'CariId' => 'Account ID',
            'FisId' => 'Receipt ID',
            'Tutar' => 'Amount',
            'ParaBirimi' => 'Currency',
            'Aciklama' => 'Description',
            'OdemeYontemi' => 'Payment Method',
            'cash_session_id' => 'Cash Session ID',
            'IslemYapan' => 'Processed By',
            'OlusturulmaTarihi' => 'Created At',
            'GuncellenmeTarihi' => 'Updated At',
            'carikod' => 'Cari Kod',
            'cek_no' => 'Check No',
            'vadetarihi' => 'Due Date',
        ];
    }

    /**
     * Satisfisleri ile ilişki (opsiyonel)
     */
    public function getSatisfis()
    {
        return $this->hasOne(Satisfisleri::class, ['FisId' => 'FisId']);
    }

    /**
     * Kaydetmeden önce tarihleri otomatik ata
     */
    public function beforeSave($insert)
    {
        if (parent::beforeSave($insert)) {
            $now = date('Y-m-d H:i:s');
    
            if ($insert) {
                $this->OlusturulmaTarihi = $now;
                $this->HareketTarihi = $now;
                if($this->IslemYapan ==null)
                    $this->IslemYapan  = Yii::$app->guser->identity->id;

                // Varsayılan ParaBirimi: İngiliz Sterlini (GBP)
                if (empty($this->ParaBirimi)) {
                    $this->ParaBirimi = 'GBP';
                }
            }
    
            $this->GuncellenmeTarihi = $now;
    
            return true;
        }
        return false;
    }
    
}
