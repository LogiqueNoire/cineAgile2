package com.losagiles.CineAgile.dto;

import lombok.Data;

@Data
public class PeliculaCarteleraDTO {
    private Long idPelicula;
    private String nombre;
    private String imageUrl;
    private String sinopsis;
    
    public PeliculaCarteleraDTO(Long idPelicula, String nombre, String imageUrl, String sinopsis) {
        this.idPelicula = idPelicula;
        this.nombre = nombre;
        this.imageUrl = imageUrl;
        this.sinopsis = sinopsis;
    }

}
