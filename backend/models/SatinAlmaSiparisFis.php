<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "satin_alma_siparis_fis".
 *
 * @property int $id
 * @property string|null $tarih
 * @property string|null $notlar
 * @property string|null $user
 * @property string|null $created_at
 * @property string|null $updated_at
 * @property int|null $gun
 * @property int|null $branch_id
 * @property string|null $invoice
 * @property int|null $delivery
 * @property string|null $po_id
 * @property int|null $status
 *
 * @property SatinAlmaSiparisFisSatir[] $satinAlmaSiparisFisSatirs
 * @property SiparisTedarikciMapping[] $siparisTedarikciMappings
 */
class SatinAlmaSiparisFis extends \yii\db\ActiveRecord
{
    public $branch_code;

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'satin_alma_siparis_fis';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['tarih', 'notlar', 'user','warehouse_code' , 'po_id', 'invoice', 'type'], 'default', 'value' => null],
            [['tarih', 'created_at', 'updated_at'], 'safe'],
            [['notlar','invoice'], 'string'],
            [['user'], 'number'],
            [['po_id'], 'string', 'max' => 15],
            [[ 'warehouse_code'], 'string', 'max' => 50],
            [['gun', 'delivery', 'status', 'type'], 'integer'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'tarih' => 'Date',
            'notlar' => 'Notes',
            'user' => 'User',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'gun' => 'Stock Coverage (Days)',
            'delivery' => 'Lead Time (Days)',
            'warehouse_code' => 'Warehouse',
            'po_id' => 'PO ID',
            'invoice' => 'Invoice',
            'branch_code' => 'Branch',
            'status' => 'Status',
            'type' => 'Type',
        ];
    }

    /**
     * Gets query for [[SatinAlmaSiparisFisSatirs]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSatinAlmaSiparisFisSatirs()
    {
        return $this->hasMany(SatinAlmaSiparisFisSatir::class, ['siparis_id' => 'id']);
    }

    /**
     * Gets query for [[SiparisTedarikciMappings]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSiparisTedarikciMappings()
    {
        return $this->hasMany(SiparisTedarikciMapping::class, ['siparis_id' => 'id']);
    }

    /**
     * Gets query for [[Warehouse]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getWarehouse()
    {
        return $this->hasOne(Warehouses::class, ['warehouse_code' => 'warehouse_code']);
    }

    /**
     * Gets query for [[Employee]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getEmployee()
    {
        return $this->hasOne(Employees::class, ['id' => 'user']);
    }

    public function afterSave($insert, $changedAttributes)
    {
        parent::afterSave($insert, $changedAttributes);
        if ($insert) {
            $this->po_id = $this->generatePoId();
            $this->updateAttributes(['po_id' => $this->po_id]);
        }
    }

    private function generatePoId()
    {
        $dateStamp = date('ymd'); // YYMMDD -> 6 hane
        $twoDigitSeq = str_pad($this->id % 100, 2, '0', STR_PAD_LEFT); // 2 hanelik günlük/sıralı ek
        return "PO-{$dateStamp}{$twoDigitSeq}"; // Toplam uzunluk: 3 + 6 + 2 = 11
    }

}
