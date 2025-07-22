package database

import (
	"log"
	"os"
	"github.com/guilhermeonrails/api-go-gin/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var (
	DB  *gorm.DB
	err error
)

func ConectaComBancoDeDados() {
	host := os.Getenv("HOST")
	if host == "" {
		host = "localhost"
	}
	
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	dbport := os.Getenv("DB_PORT")
	if dbport == "" {
		dbport = "5432"
	}
	
	// Debug (sem mostrar senha)
	log.Printf("Conectando ao banco: host=%s user=%s dbname=%s port=%s", host, user, dbname, dbport)
	
	stringDeConexao := "host="+host+" user="+user+" password="+password+" dbname="+dbname+" port="+dbport+" sslmode=disable"
	DB, err = gorm.Open(postgres.Open(stringDeConexao))
	if err != nil {
		log.Printf("Erro na conexão: %v", err)
		log.Panic("Erro ao conectar com banco de dados")
	}

	log.Println("Conexão com banco estabelecida com sucesso!")
	_ = DB.AutoMigrate(&models.Aluno{})
}
